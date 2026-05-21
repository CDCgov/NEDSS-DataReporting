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
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
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
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [program_jurisdiction_oid],
     [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [investigation_status_cd], [investigation_status],
     [inv_case_status],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_user_id], [add_user_name], [add_time],
     [last_chg_user_id], [last_chg_user_name], [last_chg_time],
     [mmwr_week], [mmwr_year],
     [nac_page_case_uid],
     [outbreak_ind],
     [hospitalized_ind], [hospitalized_ind_cd],
     [diagnosis_time],
     [effective_from_time], [effective_to_time],
     [die_frm_this_illness_ind],
     [rpt_to_county_time], [earliest_rpt_to_phd_dt],
     [rpt_to_state_time], [txt])
VALUES
    (22007000,
     20000000,
     22007000,
     N'CAS22007000GA01',
     N'T',
     N'I',
     N'130001',
     N'ACTIVE',
     N'EVN', N'CASE',
     N'C', N'10190', N'Pertussis', N'VAC',
     N'PG_Pertussis_Investigation',
     22007001,
     N'O', N'Open',
     N'Confirmed',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     N'14', N'2026',
     22007000,
     N'N',
     N'No', N'N',
     '2026-03-23T00:00:00',
     '2026-03-22T00:00:00', '2026-04-10T00:00:00',
     N'N',
     '2026-03-24T00:00:00', '2026-03-23T00:00:00',
     '2026-03-26T00:00:00',
     N'Pertussis case — full-chain comparison-fixture variant.');

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
INSERT INTO [dbo].[nrt_observation]
    ([observation_uid], [class_cd], [mood_cd], [cd], [cd_desc_txt],
     [record_status_cd], [obs_domain_cd_st_1], [version_ctrl_nbr],
     [add_user_id], [add_time], [last_chg_user_id], [last_chg_time])
VALUES
    -- ===== Coded PRT* questions (db_field='code') =====
    (22007100, N'OBS', N'EVN', N'PRT001', N'Cough indicator',           N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007101, N'OBS', N'EVN', N'PRT003', N'Paroxysmal cough indicator',N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007102, N'OBS', N'EVN', N'PRT004', N'Whoop indicator',           N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007103, N'OBS', N'EVN', N'PRT005', N'Post-tussive vomiting indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007104, N'OBS', N'EVN', N'PRT006', N'Apnea indicator',           N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007105, N'OBS', N'EVN', N'PRT008', N'Cough at final interview indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007106, N'OBS', N'EVN', N'PRT011', N'Pneumonia xray result',     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007107, N'OBS', N'EVN', N'PRT012', N'Generalized/focal seizure indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007108, N'OBS', N'EVN', N'PRT013', N'Acute encephalopathy indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007109, N'OBS', N'EVN', N'PRT020', N'Antibiotics given indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007110, N'OBS', N'EVN', N'PRT029', N'Lab testing done indicator',N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007111, N'OBS', N'EVN', N'PRT031', N'Bordetella culture result', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007112, N'OBS', N'EVN', N'PRT034', N'Serology 1 result',         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007113, N'OBS', N'EVN', N'PRT038', N'Serology 2 result',         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007114, N'OBS', N'EVN', N'PRT041', N'PCR result',                N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007115, N'OBS', N'EVN', N'PRT044', N'Ever received vaccine indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007116, N'OBS', N'EVN', N'PRT046', N'Vaccine given dose number', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007117, N'OBS', N'EVN', N'PRT060', N'Epi link to other case indicator', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007118, N'OBS', N'EVN', N'PRT065', N'Transmission setting',      N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007119, N'OBS', N'EVN', N'PRT067', N'Spread beyond transmission setting', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- ===== Text PRT* questions (db_field='value_txt') =====
    (22007130, N'OBS', N'EVN', N'PRT061', N'Epi linked case ID',        N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- ===== Numeric PRT* questions (db_field='numeric_value_1') =====
    (22007140, N'OBS', N'EVN', N'PRT009', N'Cough duration in days',    N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- ===== Date PRT* questions (db_field='from_time') =====
    (22007150, N'OBS', N'EVN', N'PRT002', N'Cough onset date',          N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007151, N'OBS', N'EVN', N'PRT007', N'Final interview date',      N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007152, N'OBS', N'EVN', N'PRT030', N'Culture date',              N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007153, N'OBS', N'EVN', N'PRT033', N'Serology 1 date',           N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007154, N'OBS', N'EVN', N'PRT037', N'Serology 2 date',           N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007155, N'OBS', N'EVN', N'PRT040', N'PCR specimen date',         N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    (22007156, N'OBS', N'EVN', N'PRT045', N'Before illness last vaccine date', N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00');

-- ---------------------------------------------------------------------
-- nrt_investigation_observation: links observations to the PHC.
-- branch_type_cd='InvFrmQ' is the v_getobs* views' filter.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_investigation_observation]
    ([public_health_case_uid], [observation_id], [root_type_cd],
     [branch_id], [branch_type_cd], [batch_id])
VALUES
    (22007000, 22007100, N'PHC', 22007100, N'InvFrmQ', NULL),
    (22007000, 22007101, N'PHC', 22007101, N'InvFrmQ', NULL),
    (22007000, 22007102, N'PHC', 22007102, N'InvFrmQ', NULL),
    (22007000, 22007103, N'PHC', 22007103, N'InvFrmQ', NULL),
    (22007000, 22007104, N'PHC', 22007104, N'InvFrmQ', NULL),
    (22007000, 22007105, N'PHC', 22007105, N'InvFrmQ', NULL),
    (22007000, 22007106, N'PHC', 22007106, N'InvFrmQ', NULL),
    (22007000, 22007107, N'PHC', 22007107, N'InvFrmQ', NULL),
    (22007000, 22007108, N'PHC', 22007108, N'InvFrmQ', NULL),
    (22007000, 22007109, N'PHC', 22007109, N'InvFrmQ', NULL),
    (22007000, 22007110, N'PHC', 22007110, N'InvFrmQ', NULL),
    (22007000, 22007111, N'PHC', 22007111, N'InvFrmQ', NULL),
    (22007000, 22007112, N'PHC', 22007112, N'InvFrmQ', NULL),
    (22007000, 22007113, N'PHC', 22007113, N'InvFrmQ', NULL),
    (22007000, 22007114, N'PHC', 22007114, N'InvFrmQ', NULL),
    (22007000, 22007115, N'PHC', 22007115, N'InvFrmQ', NULL),
    (22007000, 22007116, N'PHC', 22007116, N'InvFrmQ', NULL),
    (22007000, 22007117, N'PHC', 22007117, N'InvFrmQ', NULL),
    (22007000, 22007118, N'PHC', 22007118, N'InvFrmQ', NULL),
    (22007000, 22007119, N'PHC', 22007119, N'InvFrmQ', NULL),
    (22007000, 22007130, N'PHC', 22007130, N'InvFrmQ', NULL),
    (22007000, 22007140, N'PHC', 22007140, N'InvFrmQ', NULL),
    (22007000, 22007150, N'PHC', 22007150, N'InvFrmQ', NULL),
    (22007000, 22007151, N'PHC', 22007151, N'InvFrmQ', NULL),
    (22007000, 22007152, N'PHC', 22007152, N'InvFrmQ', NULL),
    (22007000, 22007153, N'PHC', 22007153, N'InvFrmQ', NULL),
    (22007000, 22007154, N'PHC', 22007154, N'InvFrmQ', NULL),
    (22007000, 22007155, N'PHC', 22007155, N'InvFrmQ', NULL),
    (22007000, 22007156, N'PHC', 22007156, N'InvFrmQ', NULL);

-- ---------------------------------------------------------------------
-- nrt_observation_coded: coded answer values.
-- Most PRT_IND questions use YN/YNU. PRT011/PRT031/PRT034/PRT038/PRT041
-- are result codes. PRT065 is a transmission_mode_cd.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_coded]
    ([observation_uid], [ovc_code], [batch_id])
VALUES
    (22007100, N'Y', NULL),       -- PRT001 COUGH_IND
    (22007101, N'Y', NULL),       -- PRT003 PAROXYSMAL_COUGH_IND
    (22007102, N'Y', NULL),       -- PRT004 WHOOP_IND
    (22007103, N'Y', NULL),       -- PRT005 POST_TUSSIVE_VOMITING_IND
    (22007104, N'N', NULL),       -- PRT006 APNEA_IND
    (22007105, N'Y', NULL),       -- PRT008 COUGH_AT_FINAL_INTERVIEW_IND
    (22007106, N'NEG', NULL),     -- PRT011 PNEUMONIA_XRAY_RESULT (PosNegUnk-ish)
    (22007107, N'N', NULL),       -- PRT012 SEIZURE_IND
    (22007108, N'N', NULL),       -- PRT013 ACUTE_ENCEPHALOPATHY_IND
    (22007109, N'Y', NULL),       -- PRT020 ANTIBIOTICS_GIVEN_IND
    (22007110, N'Y', NULL),       -- PRT029 LAB_TESTING_DONE_IND
    (22007111, N'POS', NULL),     -- PRT031 BORDETELLA_CULTURE_RESULT
    (22007112, N'POS', NULL),     -- PRT034 SEROLOGY_1_RESULT
    (22007113, N'POS', NULL),     -- PRT038 SEROLOGY_2_RESULT
    (22007114, N'POS', NULL),     -- PRT041 PCR_RESULT
    (22007115, N'Y', NULL),       -- PRT044 EVER_RECEIVED_VACCINE_IND
    (22007116, N'3', NULL),       -- PRT046 VACCINE_GIVEN_DOSE_NBR
    (22007117, N'Y', NULL),       -- PRT060 EPI_LINK_TO_OTHER_CASE_IND
    (22007118, N'COMMUNITY', NULL), -- PRT065 TRANSMISSION_SETTING (best guess)
    (22007119, N'N', NULL);       -- PRT067 SPREAD_BEYOND_XMISSION_SETTING

-- ---------------------------------------------------------------------
-- nrt_observation_txt: text answer values.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_txt]
    ([observation_uid], [ovt_seq], [ovt_value_txt], [batch_id])
VALUES
    (22007130, 1, N'CASE-PRT-LINK-001', NULL);  -- PRT061 EPI_LINKED_TO_CASE_ID

-- ---------------------------------------------------------------------
-- nrt_observation_numeric: numeric answer values.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_numeric]
    ([observation_uid], [ovn_seq], [ovn_numeric_value_1], [batch_id])
VALUES
    (22007140, 1, 28, NULL);                    -- PRT009 COUGH_DURATION_DAYS

-- ---------------------------------------------------------------------
-- nrt_observation_date: date answer values.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_date]
    ([observation_uid], [ovd_seq], [ovd_from_date], [batch_id])
VALUES
    (22007150, 1, '2026-03-15', NULL),          -- PRT002 COUGH_ONSET_DT
    (22007151, 1, '2026-04-05', NULL),          -- PRT007 FINAL_INTERVIEW_DT
    (22007152, 1, '2026-03-20', NULL),          -- PRT030 CULTURE_DT
    (22007153, 1, '2026-03-22', NULL),          -- PRT033 SEROLOGY_1_DT
    (22007154, 1, '2026-04-05', NULL),          -- PRT037 SEROLOGY_2_DT
    (22007155, 1, '2026-03-18', NULL),          -- PRT040 PCR_SPECIMEN_DT
    (22007156, 1, '2024-09-01', NULL);          -- PRT045 BEFORE_ILLNESS_LAST_VACCINE_DT

GO

-- =====================================================================
-- Tail-EXEC: flow nrt_investigation into INVESTIGATION so the Pertussis
-- chain joins resolve. Do NOT EXEC sp_pertussis_case_datamart_postprocessing
-- here — Step 9 owns it via $PHC_UIDS.
-- =====================================================================

EXEC dbo.sp_nrt_investigation_postprocessing
    @id_list = N'22007000',
    @debug = 0;
