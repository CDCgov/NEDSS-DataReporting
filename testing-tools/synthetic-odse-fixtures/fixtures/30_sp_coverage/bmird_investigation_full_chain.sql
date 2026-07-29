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
     N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22005000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
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
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
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

-- [ODSE-only conversion] Removed the direct LDF_GROUP KEY=1 sentinel INSERT.
-- 015-sp_nrt_ldf_postprocessing self-seeds that exact sentinel unconditionally
-- (lines 31-35), so BMIRD_CASE's FK on LDF_GROUP_KEY is satisfied by the
-- pipeline. Orchestration must run sp_nrt_ldf_postprocessing before the BMIRD
-- datamart SPs (the LDF fixtures already wire this).

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

-- ---------------------------------------------------------------------
-- nrt_investigation_observation: links each observation to the PHC UID.
-- branch_type_cd='InvFrmQ' is the v_getobs* views' filter (lines 41 /
-- 26 / 25 / 25 of v_getobscode / txt / num / date views respectively).
-- branch_id = observation_uid (the observation_uid the obs-value rows
-- key on). observation_id = same — not used by the BMIRD chain directly
-- but conventional. root_type_cd is documented but not filtered.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_coded: the actual answer values for coded questions.
-- The v_getobscode view at lines 36-40 joins observation_uid + matches
-- ovc.ovc_code to the codeset code via nrt_srte_Code_value_general. We
-- author values that exist in the BM_* code sets we verified live
-- 2026-05-21 (and YN/YNU for Y/N indicator questions).
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_txt: text answer values. The v_getobstxt view at
-- line 26 filters `ovt.ovt_seq = 1` so we set ovt_seq=1 on every row.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_numeric: numeric answer values. The v_getobsnum view
-- at line 25 filters `ovn.ovn_seq = 1` so we set ovn_seq=1 on every row.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_observation_date: date answer values. The v_getobsdate view at
-- line 25 filters `ovd.ovd_seq = 1` so we set ovd_seq=1 on every row.
-- ---------------------------------------------------------------------

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

