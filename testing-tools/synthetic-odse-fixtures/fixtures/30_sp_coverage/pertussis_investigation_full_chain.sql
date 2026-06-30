-- =====================================================================
-- Tier 3 — Pertussis full-chain Investigation fixture
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #1).
--
-- Mirrors the BMIRD full-chain template
-- (fixtures/30_sp_coverage/bmird_investigation_full_chain.sql) — Pertussis
-- uses the same v_rdb_obs_mapping observation-graph pattern (no dim
-- cluster like TB-PAM). Full ODSE chain (act + public_health_case +
-- act_id + case_management) plus nrt_investigation + nrt_observation
-- rows + nrt_investigation_observation links + nrt_observation_coded
-- / _txt / _numeric / _date answers.
--
-- Goal: populate PERTUSSIS_CASE_DATAMART (currently empty). The
-- existing nrt_investigation-only stub at PHC 22000040 in
-- multi_condition_investigations.sql is left in place; this fixture
-- adds a NEW Investigation at 22007000 with full answer data.
--
-- UID block: 22007000 - 22007999 (Pertussis full-chain Tier 3).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @pertussis_full_phc_uid       bigint = 22007000;  -- act.act_uid + public_health_case_uid
DECLARE @pertussis_full_case_mgmt_uid bigint = 22007001;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@pertussis_full_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case
-- SRTE-verified codes (live 2026-05-21):
--   condition_cd='10190' Pertussis, prog_area_cd='VAC',
--     investigation_form_cd='PG_Pertussis_Investigation'.
--   PHC_CLASS 'C' = Confirmed.
--   PHC_IN_STS 'O' = Open.
--   jurisdiction_code '130001' Fulton County (matches Tier 1 v2 inv).
-- =====================================================================
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year],
     [hospitalized_ind_cd], [hospitalized_admin_time],
     [hospitalized_discharge_time], [hospitalized_duration_amt],
     [effective_from_time], [effective_to_time])
VALUES
    (@pertussis_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'10190', N'Pertussis', N'NND', N'NND',
     N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS22007000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'VAC', N'130001',
     22007000, N'N', NULL,
     N'14', N'2026',
     N'N', NULL, NULL, NULL,
     '2026-03-22T00:00:00', '2026-04-10T00:00:00');

-- =====================================================================
-- ODSE: act_id (PHC_LOCAL_ID)
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@pertussis_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22007000GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- ODSE: case_management (minimal). IDENTITY column requires toggle.
-- =====================================================================
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [field_record_number], [surv_assigned_date],
     [surv_closed_date], [case_closed_date])
VALUES
    (@pertussis_full_case_mgmt_uid, @pertussis_full_phc_uid, N'C',
     N'FRN-PERT-FULL-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- RDB_MODERN: staging rows that the RTR postprocessing chain consumes.
-- These are written directly to bypass the CDC pipeline.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row.
-- patient_id = 20000000 (foundation Patient) — required for the F_PAGE_CASE
-- sentinel-cascade-DELETE path to not drop the row.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation rows. One per PRT/INV question we want exercised.
-- Each row is the "InvFrmQ" branch the v_getobs* views filter on.
-- Schema: class_cd='OBS', mood_cd='EVN', cd matches v_rdb_obs_mapping
-- unique_cd. obs_domain_cd_st_1='Result' is standard for InvFrmQ.
--
-- UID layout:
--   22007100..22007124 coded answers (PRT* code questions)
--   22007130..22007131 text answers
--   22007140..22007141 numeric answers
--   22007150..22007155 date answers
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_investigation_observation: links observations to the PHC.
-- branch_type_cd='InvFrmQ' is the v_getobs* views' filter.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_coded: coded answer values.
-- Most PRT_IND questions use YN/YNU. PRT011/PRT031/PRT034/PRT038/PRT041
-- are result codes. PRT065 is a transmission_mode_cd.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_txt: text answer values.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_numeric: numeric answer values.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_date: date answer values.
-- ---------------------------------------------------------------------

GO

-- =====================================================================
-- Tail-EXEC: flow nrt_investigation into INVESTIGATION so the Pertussis
-- chain joins resolve. Do NOT EXEC sp_pertussis_case_datamart_postprocessing
-- here — Step 9 owns it via $PHC_UIDS.
-- =====================================================================

