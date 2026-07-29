-- =====================================================================
-- Round 4 (NO-SHORTCUT) — Hepatitis_Case datamart chain (ODSE-only)
-- =====================================================================
-- TARGET: populate dbo.HEPATITIS_CASE (0 rows) and thence dbo.hep100
--   (0/187) + hepatitis_case-derived columns, through the REAL pipeline.
--
-- ROOT CAUSE of the earlier zz_hepatitis_obs_chain.sql failure (proven
-- live, 2026-06-03):
--   The earlier fixture hung 139 HEP question observations off the
--   FOUNDATION Hep A acute PHC 22008500 (condition_cd '10110'). All 139
--   obs flowed correctly to nrt_observation -> nrt_investigation_observation
--   (branch_type_cd='InvFrmQ') -> v_rdb_obs_mapping (139 rows), AND the
--   v_rdb_obs_mapping<->nrt_srte_IMRDBMapping (RDB_table='Hepatitis_Case')
--   join produced 139 matched rows. BUT dbo.HEPATITIS_CASE stayed at 0.
--   sp_hepatitis_case_datamart_postprocessing (routine 039) builds the
--   insert from #KEY_ATTR_INIT, which is gated (line ~604) by:
--        investigation_form_cd LIKE 'INV_FORM_HEP%'
--   For PHC 22008500 the live job_flow_log step 'GENERATING #KEY_ATTR_INIT'
--   reported row_count=0, because NBS_SRTE.dbo.condition_code maps
--   condition 10110 -> investigation_form_cd='PG_Hepatitis_A_Acute_Investigation',
--   which does NOT match 'INV_FORM_HEP%'. Independently, condition 10110
--   is mapped in nrt_datamart_metadata ONLY to 'Hepatitis_Datamart'
--   (routine 013) — NOT to 'Hepatitis_Case' (routine 039) at all
--   (Hepatitis_Case is mapped to conditions 10102 / 10481 / 999999).
--   So 10110 could never drive HEPATITIS_CASE.
--
-- FIX (ODSE-only, additive): author a NEW Hepatitis investigation under
--   condition_cd '10481' (Hepatitis Non-ABC, Acute) which:
--     - maps to the Hepatitis_Case datamart in nrt_datamart_metadata, AND
--     - has condition_code.investigation_form_cd='INV_FORM_HEPGEN'
--       (matches the 'INV_FORM_HEP%' gate in routine 039).
--   The PHC gets a SubjOfPHC patient link (so ProcessDatamartData does not
--   drop it) and its own copy of the same 139 HEP question observation
--   chain (one obs per nrt_srte_IMRDBMapping unique_cd where
--   RDB_table='Hepatitis_Case') wired via InvFrmQ act_relationships to an
--   L1 form observation, which in turn is wired to the PHC via PHCInvForm.
--
-- ORCH_TODO: add 22043000 to PHC_UIDS in scripts/merge_and_verify.sh so
--   the Step-9 hepatitis SPs (039 hepatitis_case, 042 hep100) target it.
--
-- UID block (reserved 22043000-22043999 in catalog/uid_ranges.md):
--   22043000              public_health_case / act (the new HEP investigation)
--   22043001              L1 form Observation
--   22043100-22043238     139 question Observations
--
-- Foundation deps (read-only): patient 20000000 (D_PATIENT), superuser 10009282.
-- ODSE-only: no nrt_* INSERTs, no EXEC sp_*, no seed/SRTE/liquibase edits.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @ts datetime = '2026-04-01T00:00:00';
DECLARE @superuser_id bigint = 10009282;
DECLARE @phc_uid bigint = 22043000;
DECLARE @l1_uid  bigint = 22043001;

IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @phc_uid)
BEGIN
    -- ----- ODSE: act + public_health_case (condition 10481 -> INV_FORM_HEPGEN) -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@phc_uid, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid],[add_time],[add_user_id],[case_type_cd],
         [case_class_cd],[cd],[cd_desc_txt],[cd_system_cd],[cd_system_desc_txt],
         [investigation_status_cd],[last_chg_time],[last_chg_user_id],[local_id],
         [record_status_cd],[record_status_time],[status_cd],[status_time],
         [shared_ind],[version_ctrl_nbr],[prog_area_cd],[jurisdiction_cd],
         [program_jurisdiction_oid],[outbreak_ind],[outbreak_name],
         [mmwr_week],[mmwr_year])
    VALUES
        (@phc_uid, @ts, @superuser_id, N'I',
         N'C', N'10481', N'Hepatitis Non-ABC, Acute', N'NND', N'NND',
         N'O', @ts, @superuser_id, N'CAS22043000GA01',
         N'OPEN', @ts, N'A', @ts,
         N'T', 1, N'HEP', N'130001',
         @phc_uid, N'N', NULL,
         N'14', N'2026');

    INSERT INTO [dbo].[act_id]
        ([act_uid],[act_id_seq],[add_time],[add_user_id],
         [assigning_authority_cd],[assigning_authority_desc_txt],
         [last_chg_time],[last_chg_user_id],[record_status_cd],
         [record_status_time],[root_extension_txt],[type_cd],
         [type_desc_txt],[status_cd],[status_time])
    VALUES
        (@phc_uid, 1, @ts, @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         @ts, @superuser_id, N'ACTIVE',
         @ts, N'CAS22043000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', @ts);

    -- ----- ODSE: SubjOfPHC patient link (nrt_investigation.patient_id) -----
    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20000000, @phc_uid, N'SubjOfPHC', N'CASE', @ts, @superuser_id,
         @ts, @superuser_id, N'ACTIVE', @ts, N'A', @ts, N'PSN',
         N'Subject of Public Health Case');

    -- ----- L1 form observation (target of every InvFrmQ; source of PHCInvForm) -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (@l1_uid, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation]
        ([observation_uid],[cd],[cd_system_cd],[group_level_cd],[local_id],[obs_domain_cd],
         [status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr])
    VALUES
        (@l1_uid, N'INV_FORM_HepatitisInvestigation', N'NBS', N'L1', N'OBS22043001GA01', N'CLN',
         N'A', @ts, @phc_uid, N'T', 1);

    -- ----- 139 question observations + their answer values -----
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043100, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043100, N'HEP101', N'NBS', N'NEDSS Base System', N'OBS22043100GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043100, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043101, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043101, N'HEP102', N'NBS', N'NEDSS Base System', N'OBS22043101GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043101, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043102, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043102, N'HEP104', N'NBS', N'NEDSS Base System', N'OBS22043102GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043102, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043103, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043103, N'HEP106', N'NBS', N'NEDSS Base System', N'OBS22043103GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043103, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043104, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043104, N'HEP107', N'NBS', N'NEDSS Base System', N'OBS22043104GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043104, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043105, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043105, N'HEP110', N'NBS', N'NEDSS Base System', N'OBS22043105GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043105, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043106, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043106, N'HEP111', N'NBS', N'NEDSS Base System', N'OBS22043106GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043106, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043107, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043107, N'HEP112', N'NBS', N'NEDSS Base System', N'OBS22043107GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043107, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043108, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043108, N'HEP113', N'NBS', N'NEDSS Base System', N'OBS22043108GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043108, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043109, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043109, N'HEP114', N'NBS', N'NEDSS Base System', N'OBS22043109GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043109, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043110, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043110, N'HEP115', N'NBS', N'NEDSS Base System', N'OBS22043110GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043110, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043111, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043111, N'HEP116', N'NBS', N'NEDSS Base System', N'OBS22043111GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043111, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043112, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043112, N'HEP117', N'NBS', N'NEDSS Base System', N'OBS22043112GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043112, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043113, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043113, N'HEP118', N'NBS', N'NEDSS Base System', N'OBS22043113GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043113, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043114, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043114, N'HEP119', N'NBS', N'NEDSS Base System', N'OBS22043114GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043114, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043115, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043115, N'HEP120', N'NBS', N'NEDSS Base System', N'OBS22043115GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043115, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043116, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043116, N'HEP121', N'NBS', N'NEDSS Base System', N'OBS22043116GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043116, 1, 95.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043117, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043117, N'HEP122', N'NBS', N'NEDSS Base System', N'OBS22043117GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043117, 1, 55.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043118, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043118, N'HEP123', N'NBS', N'NEDSS Base System', N'OBS22043118GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043118, 1, 88.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043119, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043119, N'HEP124', N'NBS', N'NEDSS Base System', N'OBS22043119GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043119, 1, 50.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043120, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043120, N'HEP125', N'NBS', N'NEDSS Base System', N'OBS22043120GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043120, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043121, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043121, N'HEP126', N'NBS', N'NEDSS Base System', N'OBS22043121GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043121, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043122, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043122, N'HEP127', N'NBS', N'NEDSS Base System', N'OBS22043122GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043122, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043123, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043123, N'HEP129', N'NBS', N'NEDSS Base System', N'OBS22043123GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043123, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043124, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043124, N'HEP131', N'NBS', N'NEDSS Base System', N'OBS22043124GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043124, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043125, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043125, N'HEP132', N'NBS', N'NEDSS Base System', N'OBS22043125GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043125, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043126, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043126, N'HEP133', N'NBS', N'NEDSS Base System', N'OBS22043126GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043126, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043127, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043127, N'HEP134', N'NBS', N'NEDSS Base System', N'OBS22043127GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043127, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043128, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043128, N'HEP135', N'NBS', N'NEDSS Base System', N'OBS22043128GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043128, N'0');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043129, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043129, N'HEP136', N'NBS', N'NEDSS Base System', N'OBS22043129GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043129, N'0');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043130, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043130, N'HEP137', N'NBS', N'NEDSS Base System', N'OBS22043130GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043130, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043131, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043131, N'HEP138', N'NBS', N'NEDSS Base System', N'OBS22043131GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043131, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043132, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043132, N'HEP139', N'NBS', N'NEDSS Base System', N'OBS22043132GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043132, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043133, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043133, N'HEP141', N'NBS', N'NEDSS Base System', N'OBS22043133GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043133, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043134, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043134, N'HEP143', N'NBS', N'NEDSS Base System', N'OBS22043134GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043134, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043135, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043135, N'HEP144', N'NBS', N'NEDSS Base System', N'OBS22043135GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043135, N'FA');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043136, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043136, N'HEP145', N'NBS', N'NEDSS Base System', N'OBS22043136GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043136, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043137, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043137, N'HEP146', N'NBS', N'NEDSS Base System', N'OBS22043137GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043137, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043138, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043138, N'HEP147', N'NBS', N'NEDSS Base System', N'OBS22043138GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043138, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043139, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043139, N'HEP148', N'NBS', N'NEDSS Base System', N'OBS22043139GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043139, N'1');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043140, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043140, N'HEP149', N'NBS', N'NEDSS Base System', N'OBS22043140GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043140, 1, 2024.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043141, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043141, N'HEP150', N'NBS', N'NEDSS Base System', N'OBS22043141GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043141, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043142, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043142, N'HEP151', N'NBS', N'NEDSS Base System', N'OBS22043142GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043142, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043143, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043143, N'HEP152', N'NBS', N'NEDSS Base System', N'OBS22043143GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043143, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043144, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043144, N'HEP154', N'NBS', N'NEDSS Base System', N'OBS22043144GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043144, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043145, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043145, N'HEP155', N'NBS', N'NEDSS Base System', N'OBS22043145GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043145, N'0');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043146, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043146, N'HEP156', N'NBS', N'NEDSS Base System', N'OBS22043146GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043146, N'0');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043147, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043147, N'HEP157', N'NBS', N'NEDSS Base System', N'OBS22043147GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043147, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043148, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043148, N'HEP158', N'NBS', N'NEDSS Base System', N'OBS22043148GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043148, 1, 2024.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043149, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043149, N'HEP159', N'NBS', N'NEDSS Base System', N'OBS22043149GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043149, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043150, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043150, N'HEP160', N'NBS', N'NEDSS Base System', N'OBS22043150GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043150, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043151, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043151, N'HEP161', N'NBS', N'NEDSS Base System', N'OBS22043151GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043151, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043152, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043152, N'HEP162', N'NBS', N'NEDSS Base System', N'OBS22043152GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043152, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043153, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043153, N'HEP163', N'NBS', N'NEDSS Base System', N'OBS22043153GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043153, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043154, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043154, N'HEP164', N'NBS', N'NEDSS Base System', N'OBS22043154GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043154, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043155, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043155, N'HEP165', N'NBS', N'NEDSS Base System', N'OBS22043155GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043155, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043156, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043156, N'HEP166', N'NBS', N'NEDSS Base System', N'OBS22043156GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043156, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043157, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043157, N'HEP167', N'NBS', N'NEDSS Base System', N'OBS22043157GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043157, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043158, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043158, N'HEP168', N'NBS', N'NEDSS Base System', N'OBS22043158GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043158, N'F');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043159, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043159, N'HEP169', N'NBS', N'NEDSS Base System', N'OBS22043159GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043159, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043160, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043160, N'HEP170', N'NBS', N'NEDSS Base System', N'OBS22043160GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043160, N'F');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043161, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043161, N'HEP171', N'NBS', N'NEDSS Base System', N'OBS22043161GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043161, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043162, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043162, N'HEP173', N'NBS', N'NEDSS Base System', N'OBS22043162GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043162, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043163, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043163, N'HEP174', N'NBS', N'NEDSS Base System', N'OBS22043163GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043163, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043164, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043164, N'HEP176', N'NBS', N'NEDSS Base System', N'OBS22043164GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043164, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043165, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043165, N'HEP177', N'NBS', N'NEDSS Base System', N'OBS22043165GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043165, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043166, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043166, N'HEP178', N'NBS', N'NEDSS Base System', N'OBS22043166GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043166, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043167, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043167, N'HEP179', N'NBS', N'NEDSS Base System', N'OBS22043167GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043167, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043168, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043168, N'HEP180', N'NBS', N'NEDSS Base System', N'OBS22043168GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043168, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043169, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043169, N'HEP181', N'NBS', N'NEDSS Base System', N'OBS22043169GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043169, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043170, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043170, N'HEP183', N'NBS', N'NEDSS Base System', N'OBS22043170GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043170, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043171, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043171, N'HEP184', N'NBS', N'NEDSS Base System', N'OBS22043171GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043171, 1, 2024.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043172, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043172, N'HEP185', N'NBS', N'NEDSS Base System', N'OBS22043172GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043172, 1, 6.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043173, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043173, N'HEP186', N'NBS', N'NEDSS Base System', N'OBS22043173GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043173, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043174, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043174, N'HEP187', N'NBS', N'NEDSS Base System', N'OBS22043174GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043174, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043175, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043175, N'HEP188', N'NBS', N'NEDSS Base System', N'OBS22043175GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043175, N'1');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043176, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043176, N'HEP189', N'NBS', N'NEDSS Base System', N'OBS22043176GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043176, 1, 2024.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043177, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043177, N'HEP190', N'NBS', N'NEDSS Base System', N'OBS22043177GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043177, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043178, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043178, N'HEP191', N'NBS', N'NEDSS Base System', N'OBS22043178GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043178, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043179, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043179, N'HEP192', N'NBS', N'NEDSS Base System', N'OBS22043179GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043179, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043180, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043180, N'HEP194', N'NBS', N'NEDSS Base System', N'OBS22043180GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043180, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043181, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043181, N'HEP195', N'NBS', N'NEDSS Base System', N'OBS22043181GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043181, N'0');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043182, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043182, N'HEP196', N'NBS', N'NEDSS Base System', N'OBS22043182GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043182, N'0');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043183, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043183, N'HEP197', N'NBS', N'NEDSS Base System', N'OBS22043183GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043183, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043184, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043184, N'HEP198', N'NBS', N'NEDSS Base System', N'OBS22043184GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043184, 1, 2024.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043185, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043185, N'HEP199', N'NBS', N'NEDSS Base System', N'OBS22043185GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043185, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043186, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043186, N'HEP200', N'NBS', N'NEDSS Base System', N'OBS22043186GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043186, N'F');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043187, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043187, N'HEP201', N'NBS', N'NEDSS Base System', N'OBS22043187GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043187, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043188, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043188, N'HEP202', N'NBS', N'NEDSS Base System', N'OBS22043188GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043188, N'F');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043189, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043189, N'HEP203', N'NBS', N'NEDSS Base System', N'OBS22043189GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043189, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043190, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043190, N'HEP204', N'NBS', N'NEDSS Base System', N'OBS22043190GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043190, N'CM');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043191, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043191, N'HEP205', N'NBS', N'NEDSS Base System', N'OBS22043191GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043191, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043192, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043192, N'HEP206', N'NBS', N'NEDSS Base System', N'OBS22043192GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043192, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043193, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043193, N'HEP207', N'NBS', N'NEDSS Base System', N'OBS22043193GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043193, N'CM');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043194, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043194, N'HEP208', N'NBS', N'NEDSS Base System', N'OBS22043194GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043194, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043195, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043195, N'HEP209', N'NBS', N'NEDSS Base System', N'OBS22043195GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043195, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043196, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043196, N'HEP210', N'NBS', N'NEDSS Base System', N'OBS22043196GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043196, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043197, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043197, N'HEP211', N'NBS', N'NEDSS Base System', N'OBS22043197GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043197, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043198, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043198, N'HEP212', N'NBS', N'NEDSS Base System', N'OBS22043198GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043198, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043199, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043199, N'HEP213', N'NBS', N'NEDSS Base System', N'OBS22043199GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043199, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043200, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043200, N'HEP214', N'NBS', N'NEDSS Base System', N'OBS22043200GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043200, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043201, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043201, N'HEP215', N'NBS', N'NEDSS Base System', N'OBS22043201GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043201, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043202, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043202, N'HEP216', N'NBS', N'NEDSS Base System', N'OBS22043202GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043202, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043203, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043203, N'HEP217', N'NBS', N'NEDSS Base System', N'OBS22043203GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043203, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043204, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043204, N'HEP218', N'NBS', N'NEDSS Base System', N'OBS22043204GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043204, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043205, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043205, N'HEP219', N'NBS', N'NEDSS Base System', N'OBS22043205GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043205, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043206, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043206, N'HEP220', N'NBS', N'NEDSS Base System', N'OBS22043206GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043206, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043207, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043207, N'HEP221', N'NBS', N'NEDSS Base System', N'OBS22043207GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043207, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043208, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043208, N'HEP222', N'NBS', N'NEDSS Base System', N'OBS22043208GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043208, N'J');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043209, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043209, N'HEP223', N'NBS', N'NEDSS Base System', N'OBS22043209GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043209, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043210, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043210, N'HEP224', N'NBS', N'NEDSS Base System', N'OBS22043210GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043210, 1, 2024.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043211, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043211, N'HEP225', N'NBS', N'NEDSS Base System', N'OBS22043211GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_numeric] ([observation_uid],[obs_value_numeric_seq],[numeric_value_1],[numeric_scale_1]) VALUES (22043211, 1, 6.0, 0);
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043212, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043212, N'HEP226', N'NBS', N'NEDSS Base System', N'OBS22043212GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043212, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043213, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043213, N'HEP227', N'NBS', N'NEDSS Base System', N'OBS22043213GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043213, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043214, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043214, N'HEP228', N'NBS', N'NEDSS Base System', N'OBS22043214GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043214, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043215, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043215, N'HEP229', N'NBS', N'NEDSS Base System', N'OBS22043215GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043215, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043216, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043216, N'HEP230', N'NBS', N'NEDSS Base System', N'OBS22043216GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043216, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043217, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043217, N'HEP231', N'NBS', N'NEDSS Base System', N'OBS22043217GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043217, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043218, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043218, N'HEP232', N'NBS', N'NEDSS Base System', N'OBS22043218GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043218, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043219, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043219, N'HEP233', N'NBS', N'NEDSS Base System', N'OBS22043219GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043219, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043220, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043220, N'HEP234', N'NBS', N'NEDSS Base System', N'OBS22043220GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043220, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043221, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043221, N'HEP235', N'NBS', N'NEDSS Base System', N'OBS22043221GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043221, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043222, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043222, N'HEP236', N'NBS', N'NEDSS Base System', N'OBS22043222GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043222, N'B');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043223, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043223, N'HEP237', N'NBS', N'NEDSS Base System', N'OBS22043223GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_txt] ([observation_uid],[obs_value_txt_seq],[value_txt]) VALUES (22043223, 1, N'Hep A acute test note');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043224, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043224, N'HEP238', N'NBS', N'NEDSS Base System', N'OBS22043224GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043224, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043225, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043225, N'HEP241', N'NBS', N'NEDSS Base System', N'OBS22043225GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043225, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043226, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043226, N'HEP243', N'NBS', N'NEDSS Base System', N'OBS22043226GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043226, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043227, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043227, N'HEP244', N'NBS', N'NEDSS Base System', N'OBS22043227GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043227, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043228, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043228, N'HEP245', N'NBS', N'NEDSS Base System', N'OBS22043228GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043228, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043229, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043229, N'HEP246', N'NBS', N'NEDSS Base System', N'OBS22043229GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043229, N'1');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043230, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043230, N'HEP247', N'NBS', N'NEDSS Base System', N'OBS22043230GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043230, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043231, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043231, N'HEP248', N'NBS', N'NEDSS Base System', N'OBS22043231GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043231, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043232, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043232, N'HEP249', N'NBS', N'NEDSS Base System', N'OBS22043232GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043232, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043233, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043233, N'HEP250', N'NBS', N'NEDSS Base System', N'OBS22043233GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043233, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043234, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043234, N'HEP251', N'NBS', N'NEDSS Base System', N'OBS22043234GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_date] ([observation_uid],[obs_value_date_seq],[from_time]) VALUES (22043234, 1, '2026-03-20T00:00:00');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043235, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043235, N'HEP252', N'NBS', N'NEDSS Base System', N'OBS22043235GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043235, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043236, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043236, N'HEP253', N'NBS', N'NEDSS Base System', N'OBS22043236GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043236, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043237, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043237, N'HEP263', N'NBS', N'NEDSS Base System', N'OBS22043237GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043237, N'N');
    INSERT INTO [dbo].[act] ([act_uid],[class_cd],[mood_cd]) VALUES (22043238, N'OBS', N'EVN');
    INSERT INTO [dbo].[Observation] ([observation_uid],[cd],[cd_system_cd],[cd_system_desc_txt],[local_id],[status_cd],[status_time],[program_jurisdiction_oid],[shared_ind],[version_ctrl_nbr],[cd_version]) VALUES (22043238, N'HEP264', N'NBS', N'NEDSS Base System', N'OBS22043238GA01', N'A', @ts, @phc_uid, N'T', 1, N'1.0');
    INSERT INTO [dbo].[Obs_value_coded] ([observation_uid],[code]) VALUES (22043238, N'N');

    -- ----- InvFrmQ act_relationships: target=L1 form, source=each question obs -----
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043100, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043101, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043102, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043103, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043104, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043105, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043106, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043107, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043108, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043109, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043110, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043111, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043112, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043113, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043114, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043115, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043116, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043117, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043118, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043119, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043120, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043121, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043122, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043123, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043124, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043125, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043126, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043127, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043128, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043129, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043130, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043131, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043132, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043133, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043134, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043135, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043136, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043137, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043138, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043139, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043140, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043141, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043142, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043143, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043144, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043145, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043146, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043147, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043148, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043149, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043150, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043151, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043152, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043153, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043154, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043155, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043156, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043157, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043158, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043159, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043160, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043161, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043162, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043163, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043164, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043165, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043166, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043167, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043168, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043169, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043170, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043171, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043172, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043173, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043174, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043175, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043176, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043177, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043178, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043179, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043180, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043181, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043182, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043183, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043184, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043185, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043186, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043187, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043188, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043189, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043190, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043191, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043192, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043193, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043194, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043195, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043196, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043197, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043198, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043199, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043200, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043201, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043202, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043203, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043204, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043205, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043206, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043207, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043208, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043209, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043210, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043211, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043212, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043213, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043214, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043215, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043216, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043217, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043218, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043219, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043220, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043221, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043222, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043223, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043224, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043225, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043226, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043227, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043228, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043229, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043230, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043231, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043232, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043233, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043234, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043235, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043236, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043237, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');
    INSERT INTO [dbo].[Act_relationship] ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],[record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],[target_class_cd],[type_desc_txt]) VALUES (@l1_uid, 22043238, N'InvFrmQ', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts, N'OBS', N'Investigation Form Question');

    -- PHCInvForm: target = PHC, source = L1 form observation.
    INSERT INTO [dbo].[Act_relationship]
        ([target_act_uid],[source_act_uid],[type_cd],[add_time],[last_chg_time],
         [record_status_cd],[record_status_time],[source_class_cd],[status_cd],[status_time],
         [target_class_cd],[type_desc_txt])
    VALUES
        (@phc_uid, @l1_uid, N'PHCInvForm', @ts, @ts, N'ACTIVE', @ts, N'OBS', N'A', @ts,
         N'CASE', N'PHC Investigation Form');
END;
GO

-- Bump last_chg_time so CDC re-emits the investigation and the service
-- re-runs sp_investigation_event, building nrt_investigation_observation
-- with the InvFrmQ branches for this PHC.
UPDATE [NBS_ODSE].[dbo].[public_health_case]
   SET [last_chg_time] = SYSDATETIME()
 WHERE public_health_case_uid = 22043000;
GO
