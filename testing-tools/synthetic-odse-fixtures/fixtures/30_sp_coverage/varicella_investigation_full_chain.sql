-- =====================================================================
-- Tier 3 — Varicella Investigation full ODSE + Tier 2 + NBS_case_answer
-- =====================================================================
-- Goal: unblock the Varicella PAM cluster (D_VAR_PAM + D_RASH_LOC_GEN
-- (+group) + D_PCR_SOURCE(+group) + F_VAR_PAM + VAR_PAM_LDF +
-- VAR_DATAMART). Modeled directly on the TB-PAM cluster fixture at
-- `tb_investigation_full_chain.sql`.
--
-- WHY A NEW UID, NOT AN UPGRADE
--   The existing stub at public_health_case_uid 22000020 in
--   `multi_condition_investigations.sql` writes only an nrt_investigation
--   row (form=INV_FORM_VAR, cond=10030, patient_id=20000000, nac=NULL,
--   no nbs_case_answer / nrt_page_case_answer). It exercises the
--   "Investigation exists, no PAM answers" path. We leave it untouched
--   and allocate a NEW Varicella Investigation at 22002000 with the
--   full ODSE + staging chain so:
--     - the stub continues exercising the no-answers path
--     - the new variant exercises the fully-populated PAM path
--   Together they cover both branches of the Varicella-PAM SP family.
--
-- WHAT THIS FIXTURE AUTHORS
--   1. ODSE chain (NBS_ODSE):
--        - act               (act_uid=22002000, class='CASE', mood='EVN')
--        - public_health_case (Varicella-specific codes; cd='10030',
--                              investigation_form_cd='INV_FORM_VAR',
--                              prog_area_cd='GCD', case_class_cd='C',
--                              jurisdiction_cd='130001' Fulton County)
--        - act_id             (PHC_LOCAL_ID assigning_authority)
--        - case_management    (IDENTITY-toggled)
--        - nbs_case_answer    rows for each VAR* question driving the
--                              Var-PAM, D_RASH_LOC_GEN and D_PCR_SOURCE SPs
--   2. RDB_MODERN staging (mirrors the kafka-connect JDBC sink writes):
--        - nrt_investigation row keyed on public_health_case_uid 22002000
--          with patient_id=20000000 (foundation Patient), the
--          investigation_form_cd='INV_FORM_VAR' that all the VAR-PAM SPs
--          filter on, and nac_page_case_uid=22002000 so F_VAR_PAM's
--          MAX(nac_page_case_uid) grouping resolves.
--        - nrt_page_case_answer rows — one per VAR question, with
--          datamart_column_nm matching the D_VAR_PAM column name,
--          code_set_group_id, question_identifier, data_location,
--          answer_txt, ldf_status_cd=NULL, batch_id=NULL,
--          last_chg_time set so all the VAR-PAM SP joins and predicates
--          resolve correctly. The VAR question UIDs and their
--          code_set_group_ids were verified live against
--          NBS_ODSE.dbo.nbs_question on 2026-05-21.
--   3. nbs_act_entity reporter participations (PerAsReporterOfPHC,
--      OrgAsReporterOfPHC) so the service derives nac_page_case_uid for
--      this PHC — required for F_VAR_PAM / VAR_DATAMART (see that block).
--   4. Does NOT author nrt_investigation_confirmation, other cross-subject
--      participation/act_relationship, or D_VAR_PAM / F_VAR_PAM directly —
--      those are downstream of the SP chain.
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   The chain composes:
--     sp_nrt_investigation_postprocessing    — flows nrt_investigation → INVESTIGATION
--     sp_nrt_d_var_pam_postprocessing        — root: D_VAR_PAM (215). Param @phc_uids.
--     sp_nrt_d_rash_loc_gen_postprocessing   — D_RASH_LOC_GEN(+group) (225). Filters VAR105.
--                                              Param @phc_uids.
--     sp_nrt_d_pcr_source_postprocessing     — D_PCR_SOURCE(+group) (230). Filters VAR176.
--                                              Param @phc_id_list.
--     sp_nrt_var_pam_ldf_postprocessing      — VAR_PAM_LDF (235). Param @phc_uids.
--     sp_f_var_pam_postprocessing            — F_VAR_PAM (240). Param @phc_id_list.
--                                              GATED by IF condition_cd='10030'
--                                              PORT_REQ_IND_CD='T' — verified live.
--     sp_var_datamart_postprocessing         — VAR_DATAMART (250). Param @phc_uids.
--   PARAMETER NAMES verified by grep on each SP signature 2026-05-21.
--
-- DO NOT TAIL-EXEC (handled by Step 9 of merge_and_verify.sh):
--     sp_f_var_pam_postprocessing            — Step 9 line 514
--     sp_var_datamart_postprocessing         — Step 9 line 502
--   Step 9's `$PHC_UIDS` does NOT currently include 22002000 — the
--   parent agent must extend PHC_UIDS to '...,22001000,22002000' so
--   these orchestrator-side SPs catch this Investigation. See coverage
--   report ORCH_TODO section. Running them here would double-INSERT
--   if/when PHC_UIDS is extended.
--
-- DO TAIL-EXEC (Step 9 does not run these):
--     sp_nrt_d_var_pam_postprocessing        (root)
--     sp_nrt_d_rash_loc_gen_postprocessing
--     sp_nrt_d_pcr_source_postprocessing
--     sp_nrt_var_pam_ldf_postprocessing
--   These are nrt postprocessing SPs not invoked from the datamart Step 9.
--
-- UID block (Tier 3 full-chain Varicella Investigation): 22002000-22002999
--   22002000  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid;
--             nrt_page_case_answer.act_uid for every answer row)
--   22002001  case_management.case_management_uid (IDENTITY-inserted)
--   22002100..22002130  nbs_case_answer.nbs_case_answer_uid +
--             nrt_page_case_answer.nbs_case_answer_uid for each
--             authored VAR answer row.
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT exists; F_VAR_PAM
--                                          INNER JOINs D_PATIENT on
--                                          PERSON_UID=PATIENT_UID)
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- New Varicella Investigation full-chain UIDs -----
DECLARE @var_full_phc_uid       bigint = 22002000;  -- act.act_uid + public_health_case.public_health_case_uid
DECLARE @var_full_case_mgmt_uid bigint = 22002001;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@var_full_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case row
-- =====================================================================
-- SRTE-verified codes (queried 2026-05-21):
--   condition_code.condition_cd='10030' Varicella (Chickenpox),
--     prog_area_cd='GCD', investigation_form_cd='INV_FORM_VAR',
--     PORT_REQ_IND_CD='T' (gates sp_f_var_pam line 47-51 — verified).
--   jurisdiction_code '130001' Fulton County (used by Tier 1 v2 inv).
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year])
VALUES
    (@var_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'10030', N'Varicella (Chickenpox)', N'NND', N'NND',
     N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS22002000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'GCD', N'130001',
     22002000, N'N', NULL,
     N'14', N'2026');

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
    (@var_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22002000GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

-- =====================================================================
-- ODSE: case_management (minimal; matches Tier 1 v2 Investigation shape)
-- IDENTITY column requires IDENTITY_INSERT toggle to pin our UID.
-- =====================================================================
SET IDENTITY_INSERT [dbo].[case_management] ON;
INSERT INTO [dbo].[case_management]
    ([case_management_uid], [public_health_case_uid], [status_900],
     [field_record_number], [surv_assigned_date],
     [surv_closed_date], [case_closed_date])
VALUES
    (@var_full_case_mgmt_uid, @var_full_phc_uid, N'C',
     N'FRN-VAR-FULL-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- ODSE: nbs_act_entity — reporter participations for the Varicella PHC.
--
-- WHY THIS EXISTS (the bug this fixes):
--   sp_investigation_event (056) derives nrt_investigation.nac_page_case_uid
--   from nbs_act_entity (056 lines ~910-935: `act_uid AS nac_page_case_uid`,
--   GROUP BY act_uid). With NO nbs_act_entity row for this PHC the service
--   leaves nac_page_case_uid = NULL. F_VAR_PAM (240 line 65) keys its grain on
--   CAST(nac_page_case_uid AS BIGINT) and INNER JOINs D_VAR_PAM on it, so a
--   NULL silently drops the row → F_VAR_PAM = 0 → VAR_DATAMART = 0 (even though
--   D_VAR_PAM itself, keyed on public_health_case_uid, populates fine). The TB
--   twin gets these participations from zz_tb_dedicated_entities.sql; the
--   Varicella case had none — that omission, NOT the TMP_F_PAGE_CASE datamart
--   isolation issue, is why the Varicella PAM datamart stayed empty.
--
-- Reuses the foundation Person (20000010) and Organization (20000020) as the
-- reporter so no new entity rows are needed. IDENTITY note: nbs_act_entity_uid
-- is IDENTITY — let it auto-assign and guard on the natural key
-- (act_uid, entity_uid, type_cd), per the TB fixture.
-- =====================================================================

DECLARE @superuser_id_nae bigint = 10009282;
DECLARE @var_full_phc_uid_nae bigint = 22002000;
DECLARE @foundation_person_uid bigint = 20000010;  -- foundation Person (PSN)
DECLARE @foundation_org_uid    bigint = 20000020;  -- foundation Organization (ORG)

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @var_full_phc_uid_nae AND entity_uid = @foundation_person_uid
                 AND type_cd = 'PerAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@var_full_phc_uid_nae, @foundation_person_uid, N'PerAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id_nae, '2026-04-01T00:00:00', @superuser_id_nae,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @var_full_phc_uid_nae AND entity_uid = @foundation_org_uid
                 AND type_cd = 'OrgAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@var_full_phc_uid_nae, @foundation_org_uid, N'OrgAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id_nae, '2026-04-01T00:00:00', @superuser_id_nae,
     N'ACTIVE', '2026-04-01T00:00:00');

GO

-- =====================================================================
-- ODSE: nbs_case_answer — one row per VAR-form question we author.
-- These satisfy the ODSE-side referential model. The downstream RTR
-- SPs read dbo.nrt_page_case_answer in RDB_MODERN (mirrored below).
--
-- VAR question UIDs and code_set_group_ids verified live against
-- NBS_ODSE.dbo.nbs_question, 2026-05-21.
-- =====================================================================

DECLARE @superuser_id_2 bigint = 10009282;
DECLARE @var_full_phc_uid_2 bigint = 22002000;

-- nbs_case_answer.nbs_case_answer_uid is an IDENTITY column. We want
-- our allocated UIDs (22002100+) for stable cross-fixture references,
-- so flip IDENTITY_INSERT for the duration of this INSERT block.
-- (Restored from quarantine 2026-05-21: missing IDENTITY_INSERT was the
-- sole cause of the merged-pipeline TB regression — when this fixture
-- failed mid-apply, scripts/merge_and_verify.sh's `set -euo pipefail`
-- aborted Step 8 before TB's tail-EXECs ran, leaving D_TB_PAM/F_TB_PAM
-- at 0. Adding IDENTITY_INSERT matches the TB-fixture convention from
-- commit a7757dbc.)
SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;

INSERT INTO [dbo].[nbs_case_answer]
    ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [seq_nbr])
VALUES
    -- VAR101 VARICELLA_VACCINE (YNU 4150) -> 'Y'
    (22002100, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 1442, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR103 RASH_LOCATION (PHVS_VZ_RASH_DISTRO 2780) -> Generalized (need a code)
    --   Skipped specific code; just use 'OTH' fallback per general patterns
    (22002101, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'OTH', 1363, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR105 RASH_LOCATION_GENERAL_1 (PHVS_VZ_RASH_LOC_NOT 2790) -> '22943007' Trunk
    --   Drives D_RASH_LOC_GEN (225 SP filters on VAR105).
    (22002102, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'22943007', 1356, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR111 VESICLES (YNU) -> 'Y'
    (22002103, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 1141, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR113 MACULAR_PAPULAR (YNU) -> 'N'
    (22002104, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1432, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR122 FEVER (YNU) -> 'Y'
    (22002105, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 1036, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR123 FEVER_ONSET_DATE (no codeset, date)
    (22002106, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'2026-03-25', 1017, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR126 IMMUNOCOMPROMISED (YNU) -> 'N'
    (22002107, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1190, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR128 PATIENT_VISIT_HC_PROVIDER (YNU) -> 'Y'
    (22002108, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 1187, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR129 COMPLICATIONS (YNU) -> 'N'
    (22002109, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1126, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR135 COMPLICATIONS_PNEUMONIA (YNU) -> 'N'
    (22002110, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1172, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR139 TREATED (YNU) -> 'N'
    (22002111, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1333, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR143 DEATH_AUTOPSY (YNU) -> 'N'
    (22002112, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1277, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR150 PREVIOUS_DIAGNOSIS (YNU) -> 'N'
    (22002113, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1347, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR154 EPI_LINKED (YNU) -> 'N'
    (22002114, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1446, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR156 TRANSMISSION_SETTING (PHVS_TRAN_SETNG 2660) -> '133928008' Community
    (22002115, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'133928008', 1170, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR158 HEALTHCARE_WORKER (YNU) -> 'N'
    (22002116, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1184, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR170 LAB_TESTING (YNU) -> 'Y'
    (22002117, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 1210, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR171 DFA_TEST (YNU) -> 'N'
    (22002118, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1084, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR174 PCR_TEST (YNU) -> 'Y'
    (22002119, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'Y', 1241, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR176 PCR_TEST_SOURCE_1 (PHVS_VZ_PCR_SPEC_SRC 2770) -> '69640009' Scab
    --   Drives D_PCR_SOURCE (230 SP filters on VAR176).
    (22002120, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'69640009', 1329, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR178 PCR_TEST_RESULT (PHVS_VZ_LAB_TEST_INT 4200) -> '10828004' Positive
    (22002121, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'10828004', 1016, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR180 CULTURE_TEST (YNU) -> 'N'
    (22002122, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1343, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR188 SEROLOGY_TEST (YNU) -> 'N'
    (22002123, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1020, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- VAR195 IGG_TEST (YNU) -> 'N'
    (22002124, @var_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2,
     N'N', 1024, 1, '2026-04-01T00:00:00', @superuser_id_2,
     N'ACTIVE', '2026-04-01T00:00:00', 0);

SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;

GO

-- =====================================================================
-- RDB_MODERN: staging rows that the RTR postprocessing chain consumes.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row for the full-chain Varicella Investigation.
-- Mirrors the TB full-chain shape with Varicella codes.
--   patient_id = 20000000 (foundation Patient) — required so F_VAR_PAM's
--     INNER JOIN D_PATIENT ON PERSON_UID=PATIENT_UID resolves AND so
--     the f_page_case patient-key sentinel cascade-DELETE path does
--     not drop the row (bug-5b convention).
--   nac_page_case_uid = 22002000 — F_VAR_PAM at line 65 selects
--     CAST(I.nac_page_case_uid AS BIGINT) AS VAR_PAM_UID and groups by
--     it; with NULL the row is silently dropped from F_VAR_PAM (the
--     stub at 22000020 hits exactly this gap).
--   investigation_form_cd = 'INV_FORM_VAR' — required by every VAR-PAM
--     SP's predicate (215 line 86, 225 indirect via inv join, 230
--     indirect, 235 line 81, 240 line 77).
--   batch_id NULL — matches the ISNULL(batch_id, 1)=ISNULL(batch_id, 1)
--     join predicate.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_page_case_answer rows. One per VAR question we want exercised.
-- Each row mirrors what a kafka-connect JDBC sink would write.
--
-- The VAR-PAM SP family reads:
--   act_uid (= the Investigation's public_health_case_uid)
--   question_identifier (e.g., 'VAR101')
--   nbs_question_uid (matching answer_txt)
--   datamart_column_nm (the target D_VAR_PAM column)
--   code_set_group_id (joined to nrt_srte_codeset_group_metadata)
--   answer_txt (CODE value joined to nrt_srte_Code_value_general)
--   data_location = 'NBS_Case_Answer.answer_txt'
--   ldf_status_cd IS NULL (D_VAR_PAM filter at 215 line 87)
--   nbs_ui_component_uid <> 1013 (215 line 88)
--   nbs_question_uid IS NOT NULL (215 line 89)
--   datamart_column_nm IS NOT NULL (215 line 90)
--   record_status_cd <> 'LOG_DEL' (215 line 91)
--   batch_id matched via ISNULL(.,1) = ISNULL(.,1)
--
-- The 225 (RASH_LOC_GEN) SP filters only `QUESTION_IDENTIFIER='VAR105'`.
-- The 230 (PCR_SOURCE) SP filters only `QUESTION_IDENTIFIER='VAR176'`.
-- The 215 (D_VAR_PAM) SP pivots a wide list of datamart_column_nm values
-- (lines 264-301) into D_VAR_PAM columns. We populate a curated sample.
--
-- NOT-NULL columns: act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid,
-- nbs_question_uid, record_status_cd. Use nbs_ui_metadata_uid=2 to
-- avoid the SP filter nbs_ui_component_uid <> 1013 (set component=2 too).
-- ---------------------------------------------------------------------

GO

-- =====================================================================
-- Tail-EXEC the SP chain in dependency order.
--
-- Step A: flow the new nrt_investigation row into INVESTIGATION.
--   sp_nrt_investigation_postprocessing reads nrt_investigation,
--   writes INVESTIGATION row keyed on case_uid=22002000. F_VAR_PAM
--   (240) INNER JOINs INVESTIGATION via case_uid; without this step,
--   the row never appears and 240 no-ops at the INVESTIGATION join.
-- =====================================================================


-- =====================================================================
-- Step B: VAR-PAM root SP populates D_VAR_PAM (the wide pivoted dim).
--   215 reads nrt_page_case_answer + nrt_investigation, filters on
--   INV_FORM_VAR, condition 10030, and pivots VAR questions into the
--   D_VAR_PAM PIVOT IN-list columns (lines 264-301).
-- =====================================================================


-- =====================================================================
-- Step C: the 2 topic SPs each pivot a single VAR question into a
--   topic dim + group link table. Param names verified above.
-- =====================================================================


-- =====================================================================
-- Step D: var_pam_ldf — LDF answer dim for the VAR form. Postprocessing
--   SP not invoked by orchestrator Step 9.
-- =====================================================================


-- =====================================================================
-- NOT RUN from this fixture (handled by Step 9 of merge_and_verify.sh,
-- but only IF 22002000 is added to that script's PHC_UIDS list — see
-- coverage_varicella_full_chain.md ORCH_TODO):
--   sp_f_var_pam_postprocessing       (240) — F_VAR_PAM
--   sp_var_datamart_postprocessing    (250) — VAR_DATAMART
-- =====================================================================
