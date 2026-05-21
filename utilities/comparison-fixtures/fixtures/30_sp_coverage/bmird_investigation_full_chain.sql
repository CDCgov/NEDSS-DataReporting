-- =====================================================================
-- Tier 3 — BMIRD (Strep pneumoniae invasive) Investigation full ODSE +
-- nrt_investigation + nrt_observation observation-graph chain.
-- =====================================================================
-- Goal: unblock the BMIRD cluster — `BMIRD_Case` (170 cols, currently
-- 0 rows), `BMIRD_STREP_PNEUMO_DATAMART` (140 cols, currently 0 rows),
-- `BMIRD_MULTI_VALUE_FIELD` (1 sentinel), `ANTIMICROBIAL` (1 sentinel),
-- and `LDF_BMIRD` (7 cols, 0 rows). The chain pivots observation-coded
-- / -txt / -numeric / -date answers (BMD* and INV* unique_cds) through
-- the legacy `v_rdb_obs_mapping` view into BMIRD_Case columns and
-- BMIRD_Multi_Value_field rows, then sp_bmird_strep_pneumo_datamart_-
-- postprocessing INNER JOINs BMIRD_CASE on CONDITION_CD IN
-- ('11717','11720','11723') and pivots multi-value rows and Antimicrobial
-- batch-entry rows into the wide BMIRD_STREP_PNEUMO_DATAMART columns.
--
-- WHY A NEW UID, NOT AN UPGRADE
--   The existing stub at public_health_case_uid 22000100 in
--   `multi_condition_investigations.sql` writes only an nrt_investigation
--   row (no observations, no BMD answers). It exercises the
--   "Investigation exists, no BMIRD answers" path. We leave it untouched
--   and allocate a NEW BMIRD Strep pneumo Investigation at 22005000 with
--   the full ODSE + observation chain so:
--     - the stub continues exercising the no-answers path
--     - the new variant exercises the fully-populated answers path
--   Together they cover both branches of the BMIRD SP family.
--
-- WHAT THIS FIXTURE AUTHORS
--   1. ODSE chain (NBS_ODSE):
--        - act               (act_uid=22005000, class='CASE', mood='EVN')
--        - public_health_case (BMIRD-specific codes; cd='11717',
--                              investigation_form_cd='INV_FORM_BMDSP',
--                              prog_area_cd='BMIRD', case_class_cd='C',
--                              jurisdiction_cd='130001' Fulton County)
--        - act_id             (PHC_LOCAL_ID assigning_authority)
--        - case_management    (minimal; per Tier 1 v2 shape)
--   2. RDB_MODERN staging (mirrors kafka-connect JDBC sink writes):
--        - nrt_investigation row keyed on public_health_case_uid 22005000
--          with patient_id=20000000 (foundation Patient — required so
--          BMIRD_STREP_PNEUMO_DATAMART's D_PATIENT LEFT JOIN resolves;
--          see 140 SP lines 127-128), the investigation_form_cd
--          'INV_FORM_BMDSP', mmwr_week='14', mmwr_year='2026',
--          ill_onset_dt / illness_end_dt / hsptl_admission_dt populated
--          so BMIRD_STREP_PNEUMO_DATAMART hospitalization /
--          illness-date columns flow through.
--        - nrt_observation rows — one per BMD/INV question we author
--          (class_cd='OBS', mood_cd='EVN', cd='BMD120' etc.).
--        - nrt_investigation_observation rows linking each observation
--          to public_health_case_uid 22005000 with branch_type_cd='InvFrmQ'
--          (the v_getobs* views' filter).
--        - nrt_observation_coded / _txt / _numeric / _date rows providing
--          the answer values. The v_rdb_obs_mapping view joins these
--          to nrt_srte_IMRDBMapping by unique_cd and pivots into either
--          BMIRD_Case columns or BMIRD_Multi_Value_field columns based
--          on RDB_table.
--   3. Does NOT author BMIRD_CASE, BMIRD_STREP_PNEUMO_DATAMART,
--      ANTIMICROBIAL, BMIRD_MULTI_VALUE_FIELD, or LDF_BMIRD directly —
--      those are downstream of the SP chain and owned by Step 9 of
--      merge_and_verify.sh.
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   The chain composes (in dependency order):
--     sp_nrt_investigation_postprocessing — flows nrt_investigation
--                                            → INVESTIGATION (CASE_UID=22005000).
--                                            Required because
--                                            sp_bmird_case_datamart_postprocessing's
--                                            #OLD_AM_GRP_KEYS INNER JOIN at
--                                            line 314 reads dbo.INVESTIGATION,
--                                            and V_NRT_INV_KEYS_ATTRS_MAPPING
--                                            INNER JOINs INVESTIGATION on
--                                            case_uid (line 134 of view).
--   DO NOT tail-EXEC sp_bmird_case_datamart_postprocessing (Step 9
--   line 505 owns it), sp_bmird_strep_pneumo_datamart_postprocessing
--   (Step 9 line 506), or sp_ldf_bmird_datamart_postprocessing (Step
--   9 line 526). They would produce duplicate or stale rows if invoked
--   twice in a single merged run.
--
-- ORCHESTRATOR INTEGRATION
--   The merged orchestrator's PHC_UIDS list (scripts/merge_and_verify.sh
--   line 446) must include 22005000 so Step 9's bmird datamart SPs pick
--   up our new full-chain UID. The orchestrator diff is applied alongside
--   this fixture.
--
-- UID block (Tier 3 full-chain BMIRD Strep pneumo Investigation):
-- 22005000-22005999
--   22005000  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid;
--             nrt_investigation_observation.public_health_case_uid for
--             every authored observation row)
--   22005001  case_management.case_management_uid (IDENTITY-inserted)
--   22005100..22005149  nrt_observation.observation_uid (one per BMD/INV
--             coded/txt/numeric/date question authored). 50-UID
--             contiguous block; current usage 24 UIDs (BMD coded x10,
--             BMD txt x4, BMD numeric x4, BMD date x2, BMIRD_MVF x4 —
--             Multi_Value_field rows are also nrt_observation_coded
--             entries, just routed by RDB_table='BMIRD_Multi_Value_field'
--             in nrt_srte_IMRDBMapping).
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT exists; the BMIRD
--                                          chain's LEFT JOIN D_PATIENT
--                                          on PATIENT_KEY resolves
--                                          through patient_id=20000000 →
--                                          V_NRT_INV_KEYS_ATTRS_MAPPING's
--                                          patient_key=N — the D_PATIENT
--                                          row for foundation Patient is
--                                          populated by Tier 1.)
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- New BMIRD Strep pneumo Investigation full-chain UIDs -----
DECLARE @bmird_full_phc_uid       bigint = 22005000;  -- act.act_uid + public_health_case.public_health_case_uid
DECLARE @bmird_full_case_mgmt_uid bigint = 22005001;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@bmird_full_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case row
-- =====================================================================
-- SRTE-verified codes (queried 2026-05-21):
--   condition_code.condition_cd='11717' Strep pneumoniae invasive,
--     prog_area_cd='BMIRD', investigation_form_cd='INV_FORM_BMDSP'.
--   program_area_code.prog_area_cd='BMIRD'.
--   code_value_general PHC_CLASS 'C' (Confirmed).
--   code_value_general PHC_IN_STS 'O' (Open).
--   jurisdiction_code '130001' Fulton County (used by Tier 1 v2 inv).
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
    (@bmird_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'11717', N'Strep pneumoniae, invasive', N'NND', N'NND',
     N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS22005000GA01',
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'BMIRD', N'130001',
     22005000, N'N', NULL,
     N'14', N'2026',
     N'Y', '2026-03-25T08:00:00', '2026-04-02T12:00:00', 8,
     '2026-03-22T00:00:00', '2026-04-10T00:00:00');

-- =====================================================================
-- ODSE: act_id (PHC_LOCAL_ID) — matches the canonical Investigation pattern
-- =====================================================================
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@bmird_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22005000GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- ODSE: case_management (minimal; matches Tier 1 v2 Investigation shape).
-- IDENTITY column requires IDENTITY_INSERT toggle to pin our UID.
-- =====================================================================
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [field_record_number], [surv_assigned_date],
     [surv_closed_date], [case_closed_date])
VALUES
    (@bmird_full_case_mgmt_uid, @bmird_full_phc_uid, N'C',
     N'FRN-BMIRD-FULL-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- RDB_MODERN: staging rows that the RTR postprocessing chain consumes.
-- These are written directly to bypass the CDC pipeline (per STRATEGY.md
-- "Convention: postprocessing SPs read NRT staging only — never ODSE").
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- Seed an LDF_GROUP sentinel row at KEY=1 if missing. BMIRD_CASE has a
-- FK constraint on LDF_GROUP_KEY (see 040 SP line 814 + table DDL);
-- V_NRT_INV_KEYS_ATTRS_MAPPING's COALESCE(lg.ldf_group_key, 1) fallback
-- yields 1, which the FK then enforces against LDF_GROUP. Baseline
-- 6.0.18.1 leaves LDF_GROUP empty; sp_nrt_ldf_postprocessing populates
-- it only when LDF rows exist for the Investigation (out of scope for
-- this fixture). One-row sentinel seed is the conventional fix used by
-- other fact tables (RDB_DATE, ANTIMICROBIAL_GROUP, etc.).
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.LDF_GROUP WHERE LDF_GROUP_KEY = 1)
BEGIN
    INSERT INTO dbo.LDF_GROUP (LDF_GROUP_KEY, BUSINESS_OBJECT_UID)
    VALUES (1, NULL);
END;
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row for the full-chain BMIRD Strep pneumo Investigation.
-- Mirrors the v2 Tier 1 Investigation shape (fixtures/10_subjects/
-- investigation.sql) with BMIRD-specific codes:
--   patient_id = 20000000 (foundation Patient) — required so
--     BMIRD_STREP_PNEUMO_DATAMART's `LEFT JOIN D_PATIENT P ON
--     BC.PATIENT_KEY = P.PATIENT_KEY` (140 SP line 127-128) resolves
--     through V_NRT_INV_KEYS_ATTRS_MAPPING's `coalesce(dpat.patient_key, 1)`
--     (009-v_nrt_inv_keys_attrs_mapping line 118) and the f_page_case
--     sentinel-key cascade-DELETE path does not drop the row.
--   illness_onset_dt / illness_end_dt / hsptl_admission_dt /
--     hsptl_discharge_dt / earliest_rpt_to_state_dt — populated so the
--     #BMIRD_PAT_INV (140 SP line 154-168) and #BMIRD_WITH_EVENT_DATE
--     (line 204-237) blocks have non-NULL date inputs.
--   die_frm_this_illness_ind='N' so DIE_FRM_THIS_ILLNESS_IND non-NULL.
--   inv_case_status='Confirmed' for CASE_STATUS column.
--   inv_comments txt for GENERAL_COMMENTS column.
--   case_type_cd = 'I' (so the SP's `WHERE i.CASE_TYPE <> 'S'`
--     predicate at 140 line 180 keeps the row).
--   batch_id NULL — matches the ISNULL(batch_id, 1) = ISNULL(batch_id, 1)
--     join predicate everywhere.
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
     [hospitalized_admin_time], [hospitalized_discharge_time],
     [hospitalized_duration_amt],
     [diagnosis_time],
     [effective_from_time], [effective_to_time],
     [die_frm_this_illness_ind],
     [rpt_to_county_time], [earliest_rpt_to_phd_dt],
     [rpt_to_state_time], [txt])
VALUES
    (22005000,                              -- public_health_case_uid
     20000000,                              -- patient_id (foundation Patient)
     22005000,                              -- program_jurisdiction_oid
     N'CAS22005000GA01',                    -- local_id
     N'T',                                  -- shared_ind
     N'I',                                  -- case_type_cd (NOT 'S')
     N'130001',                             -- jurisdiction_cd (Fulton)
     N'ACTIVE',                             -- record_status_cd
     N'EVN', N'CASE',                       -- mood_cd, class_cd
     N'C', N'11717', N'Strep pneumoniae, invasive', N'BMIRD',
     N'INV_FORM_BMDSP',                     -- investigation_form_cd
     22005001,                              -- case_management_uid
     N'O', N'Open',
     N'Confirmed',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     N'14', N'2026',
     22005000,                              -- nac_page_case_uid
     N'N',                                  -- outbreak_ind
     N'Yes', N'Y',                          -- hospitalized_ind, hospitalized_ind_cd
     '2026-03-25T08:00:00', '2026-04-02T12:00:00',
     8,                                     -- hsptl_duration_amt (days)
     '2026-03-23T00:00:00',                 -- diagnosis_time
     '2026-03-22T00:00:00', '2026-04-10T00:00:00',
     N'N',                                  -- die_frm_this_illness_ind
     '2026-03-24T00:00:00', '2026-03-23T00:00:00',
     '2026-03-26T00:00:00',
     N'BMIRD Strep pneumo invasive case — full-chain comparison-fixture variant.');

-- ---------------------------------------------------------------------
-- nrt_observation rows. One per BMD/INV question we want exercised.
-- Each row is the "InvFrmQ" branch the v_getobs* views filter on
-- (002-v_getobscode line 41, 003-v_getobsdate line 25, etc.).
-- Schema: class_cd='OBS', mood_cd='EVN', cd matches IMRDBMapping
-- unique_cd. obs_domain_cd_st_1='Result' is standard for InvFrmQ
-- observations.
--
-- NOT-NULL columns:
--   observation_uid (bigint), version_ctrl_nbr (smallint, default 1).
-- All other columns optional.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation]
    ([observation_uid], [class_cd], [mood_cd], [cd], [cd_desc_txt],
     [record_status_cd], [obs_domain_cd_st_1], [version_ctrl_nbr],
     [add_user_id], [add_time], [last_chg_user_id], [last_chg_time])
VALUES
    -- ===== BMIRD_Case coded answers (BMD coded → BMIRD_Case columns) =====
    -- BMD120 BACTERIAL_SPECIES_ISOLATED -> '11717' (BM_SPEC_ISOL codeset)
    (22005100, N'OBS', N'EVN', N'BMD120', N'Bacterial species isolated',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD100 ABCCASE -> 'Y' (YN codeset)
    (22005101, N'OBS', N'EVN', N'BMD100', N'ABCs case definition',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD103 TRANSFERED_IND -> 'N' (YNU codeset)
    (22005102, N'OBS', N'EVN', N'BMD103', N'Patient transferred indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD105 DAYCARE_IND -> 'N' (YNU codeset)
    (22005103, N'OBS', N'EVN', N'BMD105', N'Daycare indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD107 NURSING_HOME_IND -> 'N' (YNU codeset)
    (22005104, N'OBS', N'EVN', N'BMD107', N'Nursing home indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD111 PREGNANT_IND -> 'N' (YNU codeset)
    (22005105, N'OBS', N'EVN', N'BMD111', N'Pregnant indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD126 UNDERLYING_CONDITION_IND -> 'Y'
    (22005106, N'OBS', N'EVN', N'BMD126', N'Underlying condition indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD137 OXACILLIN_INTERPRETATION -> 'R'
    (22005107, N'OBS', N'EVN', N'BMD137', N'Oxacillin interpretation',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD138 PNEUVACC_RECEIVED_IND -> 'Y'
    (22005108, N'OBS', N'EVN', N'BMD138', N'Pneumococcal polysaccharide vaccine received',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD139 PNEUCONJ_RECEIVED_IND -> 'N'
    (22005109, N'OBS', N'EVN', N'BMD139', N'Pneumococcal conjugate vaccine received',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD140 PERSISTENT_DISEASE_IND -> 'N'
    (22005110, N'OBS', N'EVN', N'BMD140', N'Persistent disease indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD151 SAME_PATHOGEN_RECURRENT_IND -> 'N'
    (22005111, N'OBS', N'EVN', N'BMD151', N'Same pathogen recurrent indicator',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD131 CULTURE_SEROTYPE -> '19A' (text but in coded codeset for Strep)
    (22005112, N'OBS', N'EVN', N'BMD131', N'Culture serotype',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

    -- ===== BMIRD_Case text answers (BMD value_txt → BMIRD_Case columns) =====
    -- BMD119 TYPES_OF_OTHER_INFECTION (text)
    (22005120, N'OBS', N'EVN', N'BMD119', N'Other infection type free text',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD123 STERILE_SITE_OTHER (text)
    (22005121, N'OBS', N'EVN', N'BMD123', N'Other sterile site free text',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD298 OTHNONSTER (text)
    (22005122, N'OBS', N'EVN', N'BMD298', N'Other non-sterile site',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD299 OTHSEROTYPE (text)
    (22005123, N'OBS', N'EVN', N'BMD299', N'Other serotype',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

    -- ===== BMIRD_Case numeric answers (BMD numeric_value_1 → BMIRD_Case columns) =====
    -- BMD136 OXACILLIN_ZONE_SIZE (numeric mm)
    (22005130, N'OBS', N'EVN', N'BMD136', N'Oxacillin zone size in mm',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

    -- ===== BMIRD_Case date answers (BMD from_time → BMIRD_Case columns) =====
    -- BMD141 FIRST_ADDITIONAL_SPECIMEN_DT
    (22005140, N'OBS', N'EVN', N'BMD141', N'First additional specimen date',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD143 SECOND_ADDITIONAL_SPECIMEN_DT
    (22005141, N'OBS', N'EVN', N'BMD143', N'Second additional specimen date',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),

    -- ===== BMIRD_Multi_Value_field coded answers (BMD coded, RDB_table=Multi_Value_field) =====
    -- BMD118 TYPES_OF_INFECTIONS -> 'Bacteremia without focus' (drives
    --   TYPE_INFECTION_BACTEREMIA column in BMIRD_STREP_PNEUMO_DATAMART)
    (22005150, N'OBS', N'EVN', N'BMD118', N'Types of infections',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD127 UNDERLYING_CONDITION_NM -> 'Diabetes mellitus' (drives UNDERLYING_CONDITION_1)
    (22005151, N'OBS', N'EVN', N'BMD127', N'Underlying condition name',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD125 NON_STERILE_SITE -> 'Sputum' (drives NON_STERILE_SITE_1)
    (22005152, N'OBS', N'EVN', N'BMD125', N'Non-sterile site',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00'),
    -- BMD142 STREP_PNEUMO_1_CULTURE_SITES -> 'Blood' (drives ADD_CULTURE_1_SITE_1)
    (22005153, N'OBS', N'EVN', N'BMD142', N'Strep pneumo 1st additional culture site',
     N'ACTIVE', N'Result', 1, 10009282, '2026-04-01T00:00:00', 10009282, '2026-04-01T00:00:00');

-- ---------------------------------------------------------------------
-- nrt_investigation_observation: links each observation to the PHC UID.
-- branch_type_cd='InvFrmQ' is the v_getobs* views' filter (lines 41 /
-- 26 / 25 / 25 of v_getobscode / txt / num / date views respectively).
-- branch_id = observation_uid (the observation_uid the obs-value rows
-- key on). observation_id = same — not used by the BMIRD chain directly
-- but conventional. root_type_cd is documented but not filtered.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_investigation_observation]
    ([public_health_case_uid], [observation_id], [root_type_cd],
     [branch_id], [branch_type_cd], [batch_id])
VALUES
    (22005000, 22005100, N'PHC', 22005100, N'InvFrmQ', NULL),
    (22005000, 22005101, N'PHC', 22005101, N'InvFrmQ', NULL),
    (22005000, 22005102, N'PHC', 22005102, N'InvFrmQ', NULL),
    (22005000, 22005103, N'PHC', 22005103, N'InvFrmQ', NULL),
    (22005000, 22005104, N'PHC', 22005104, N'InvFrmQ', NULL),
    (22005000, 22005105, N'PHC', 22005105, N'InvFrmQ', NULL),
    (22005000, 22005106, N'PHC', 22005106, N'InvFrmQ', NULL),
    (22005000, 22005107, N'PHC', 22005107, N'InvFrmQ', NULL),
    (22005000, 22005108, N'PHC', 22005108, N'InvFrmQ', NULL),
    (22005000, 22005109, N'PHC', 22005109, N'InvFrmQ', NULL),
    (22005000, 22005110, N'PHC', 22005110, N'InvFrmQ', NULL),
    (22005000, 22005111, N'PHC', 22005111, N'InvFrmQ', NULL),
    (22005000, 22005112, N'PHC', 22005112, N'InvFrmQ', NULL),
    (22005000, 22005120, N'PHC', 22005120, N'InvFrmQ', NULL),
    (22005000, 22005121, N'PHC', 22005121, N'InvFrmQ', NULL),
    (22005000, 22005122, N'PHC', 22005122, N'InvFrmQ', NULL),
    (22005000, 22005123, N'PHC', 22005123, N'InvFrmQ', NULL),
    (22005000, 22005130, N'PHC', 22005130, N'InvFrmQ', NULL),
    (22005000, 22005140, N'PHC', 22005140, N'InvFrmQ', NULL),
    (22005000, 22005141, N'PHC', 22005141, N'InvFrmQ', NULL),
    (22005000, 22005150, N'PHC', 22005150, N'InvFrmQ', NULL),
    (22005000, 22005151, N'PHC', 22005151, N'InvFrmQ', NULL),
    (22005000, 22005152, N'PHC', 22005152, N'InvFrmQ', NULL),
    (22005000, 22005153, N'PHC', 22005153, N'InvFrmQ', NULL);

-- ---------------------------------------------------------------------
-- nrt_observation_coded: the actual answer values for coded questions.
-- The v_getobscode view at lines 36-40 joins observation_uid + matches
-- ovc.ovc_code to the codeset code via nrt_srte_Code_value_general. We
-- author values that exist in the BM_* code sets we verified live
-- 2026-05-21 (and YN/YNU for Y/N indicator questions).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_coded]
    ([observation_uid], [ovc_code], [batch_id])
VALUES
    -- BMD120 BACTERIAL_SPECIES_ISOLATED -> '11717' (Strep pneumo isolated)
    -- Note: BM_SPEC_ISOL codeset has 11720/11723 etc. The v_codeset row for
    -- BMD120 maps to BM_SPEC_ISOL; we pass the NETSS event ID '11717'.
    (22005100, N'11717', NULL),
    (22005101, N'Y', NULL),                        -- BMD100 ABCCASE
    (22005102, N'N', NULL),                        -- BMD103 TRANSFERED_IND
    (22005103, N'N', NULL),                        -- BMD105 DAYCARE_IND
    (22005104, N'N', NULL),                        -- BMD107 NURSING_HOME_IND
    (22005105, N'N', NULL),                        -- BMD111 PREGNANT_IND
    (22005106, N'Y', NULL),                        -- BMD126 UNDERLYING_CONDITION_IND
    (22005107, N'R', NULL),                        -- BMD137 OXACILLIN_INTERPRETATION (S/I/R)
    (22005108, N'Y', NULL),                        -- BMD138 PNEUVACC_RECEIVED_IND
    (22005109, N'N', NULL),                        -- BMD139 PNEUCONJ_RECEIVED_IND
    (22005110, N'N', NULL),                        -- BMD140 PERSISTENT_DISEASE_IND
    (22005111, N'N', NULL),                        -- BMD151 SAME_PATHOGEN_RECURRENT_IND
    (22005112, N'19A', NULL),                      -- BMD131 CULTURE_SEROTYPE
    -- BMIRD_Multi_Value_field rows — codes resolved by v_getobscode →
    -- text via nrt_srte_Code_value_general.code_short_desc_txt. SP 140's
    -- CASE WHEN matches on the resolved short text (line 797 etc.).
    (22005150, N'BACTEREM', NULL),    -- BMD118 BM_INFEC_TYPE → 'Bacteremia without focus'
    (22005151, N'DM', NULL),          -- BMD127 BM_UNDERL_CAUSE → 'Diabetes Mellitus'
    (22005152, N'SINUS', NULL),       -- BMD125 BM_ORG_ISO_S2 → 'Sinus' (no Sputum in this codeset)
    (22005153, N'BLOOD', NULL);       -- BMD142 BM_ORG_ISO_S1 → 'Blood'

-- ---------------------------------------------------------------------
-- nrt_observation_txt: text answer values. The v_getobstxt view at
-- line 26 filters `ovt.ovt_seq = 1` so we set ovt_seq=1 on every row.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_txt]
    ([observation_uid], [ovt_seq], [ovt_value_txt], [batch_id])
VALUES
    (22005120, 1, N'Otitis media — recurrent, with sepsis', NULL),   -- BMD119
    (22005121, 1, N'Brain biopsy tissue', NULL),                     -- BMD123
    (22005122, 1, N'Throat swab', NULL),                             -- BMD298 OTHNONSTER
    (22005123, 1, N'Serotype 19F (alternate culture)', NULL);        -- BMD299 OTHSEROTYPE

-- ---------------------------------------------------------------------
-- nrt_observation_numeric: numeric answer values. The v_getobsnum view
-- at line 25 filters `ovn.ovn_seq = 1` so we set ovn_seq=1 on every row.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_numeric]
    ([observation_uid], [ovn_seq], [ovn_numeric_value_1], [batch_id])
VALUES
    (22005130, 1, 22, NULL);                                         -- BMD136 OXACILLIN_ZONE_SIZE (22 mm)

-- ---------------------------------------------------------------------
-- nrt_observation_date: date answer values. The v_getobsdate view at
-- line 25 filters `ovd.ovd_seq = 1` so we set ovd_seq=1 on every row.
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_observation_date]
    ([observation_uid], [ovd_seq], [ovd_from_date], [batch_id])
VALUES
    (22005140, 1, '2026-03-25', NULL),                               -- BMD141 FIRST_ADDITIONAL_SPECIMEN_DT
    (22005141, 1, '2026-03-28', NULL);                               -- BMD143 SECOND_ADDITIONAL_SPECIMEN_DT

GO

-- =====================================================================
-- Tail-EXEC: flow nrt_investigation into INVESTIGATION so the BMIRD
-- chain's V_NRT_INV_KEYS_ATTRS_MAPPING (INNER JOIN INVESTIGATION on
-- case_uid, line 134 of view) and sp_bmird_strep_pneumo_datamart's
-- #INVKEYS (INNER JOIN dbo.INVESTIGATION line 53) resolve to a row.
--
-- DO NOT EXEC the BMIRD datamart SPs here — Step 9 of
-- merge_and_verify.sh owns them via $PHC_UIDS. Tail-EXECing them here
-- would produce duplicate or stale BMIRD_Case / BMIRD_STREP_PNEUMO_-
-- DATAMART rows on the orchestrated run. The orchestrator's PHC_UIDS
-- list (line 446) is updated alongside this fixture to include
-- 22005000.
-- =====================================================================

EXEC dbo.sp_nrt_investigation_postprocessing
    @id_list = N'22005000',
    @debug = 0;
