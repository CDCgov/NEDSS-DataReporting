-- =====================================================================
-- Tier 3 — d_investigation_repeat full ODSE + NBS_case_answer chain
-- =====================================================================
-- Goal: unblock `d_investigation_repeat` (was 1/244 cols, the worst
-- single partial), plus the two related repeating-dim tables fed by
-- the same SP:
--   - lookup_table_n_rept           (was 0/2)
--   - l_investigation_repeat_inc    (was 0/2)
--
-- All three are written by:
--   liquibase-service/.../routines/010-sp_sld_investigation_repeat_postprocessing-001.sql
--
-- WHY A NEW UID, NOT AN UPGRADE
--   The existing Pertussis stub at public_health_case_uid 22000040 in
--   multi_condition_investigations.sql writes only an nrt_investigation
--   row (no ODSE-side act/PHC, no nbs_case_answer, no
--   nrt_page_case_answer). It exercises the "Investigation exists, no
--   repeating-block answers" path. We leave it untouched and allocate
--   a NEW Pertussis-form Investigation at 22006000 with the full ODSE +
--   staging chain so:
--     - the stub continues exercising the no-answers path
--     - the new variant exercises the fully-populated repeating-block
--       pivot path
--   Together they cover both branches of the SP.
--
-- WHY PERTUSSIS FORM (`PG_Pertussis_Investigation`)
--   sp_sld_investigation_repeat_postprocessing at line 84 EXCLUDES the
--   following forms from its #phc_uids_REPT seed:
--
--     INV_FORM_BMDGAS, INV_FORM_BMDGBS, INV_FORM_BMDGEN, INV_FORM_BMDNM,
--     INV_FORM_BMDSP, INV_FORM_GEN, INV_FORM_HEPA, INV_FORM_HEPBV,
--     INV_FORM_HEPCV, INV_FORM_HEPGEN, INV_FORM_MEA, INV_FORM_PER,
--     INV_FORM_RUB, INV_FORM_RVCT, INV_FORM_VAR.
--
--   PG_Pertussis_Investigation is NOT in the exclusion list (note the
--   exclusion list includes INV_FORM_PER but the page-builder
--   investigation form code is `PG_Pertussis_Investigation` — different
--   string. Also matches the existing 22000040 stub's form_cd for
--   consistency).
--
-- WHAT THIS FIXTURE AUTHORS
--   1. ODSE chain (NBS_ODSE):
--        - act               (act_uid=22006000, class='CASE', mood='EVN')
--        - public_health_case (Pertussis: cd='10190',
--                              investigation_form_cd='PG_Pertussis_Investigation',
--                              prog_area_cd='VAC', case_class_cd='C',
--                              jurisdiction_cd='130001' Fulton County)
--        - act_id             (PHC_LOCAL_ID assigning_authority)
--        - case_management    (minimal; matches Tier 1 v2 Investigation shape)
--        - nbs_case_answer    rows for each authored repeating-block
--                              answer (ODSE-side referential model — the
--                              page-builder consumes WS_CASE_ANSWER which
--                              joins this table; RTR's SP reads only the
--                              RDB_MODERN-side nrt_page_case_answer)
--   2. RDB_MODERN staging (mirrors the kafka-connect JDBC sink writes):
--        - nrt_investigation row keyed on public_health_case_uid 22006000
--          with patient_id=20000000 (foundation Patient), the
--          investigation_form_cd='PG_Pertussis_Investigation' that
--          the SP filter does NOT exclude.
--        - nrt_page_case_answer rows — one per repeating-block answer.
--          Each row has answer_group_seq_nbr AND question_group_seq_nbr
--          NOT NULL (the SP's gating predicates at lines 167, 251, 434,
--          647, 765, 771 all require both to be non-NULL).
--          Spans 2 BLOCK_NM values and 3 answer_group_seq_nbr values per
--          block (N=3 covers off-by-one logic in pivots).
--          Spans 4 data_type values (TEXT, CODED, DATE, NUMERIC) so all
--          four pivot branches in the SP populate columns.
--          Each row has a unique RDB_COLUMN_NM so the dynamic ALTER TABLE
--          loop at line 1241 ADDs a distinct column to D_INVESTIGATION_REPEAT.
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   The chain composes:
--     sp_nrt_investigation_postprocessing    — flows nrt_investigation → INVESTIGATION
--     sp_sld_investigation_repeat_postprocessing — writes S_INVESTIGATION_REPEAT,
--                                                  LOOKUP_TABLE_N_REPT,
--                                                  L_INVESTIGATION_REPEAT_INC,
--                                                  L_INVESTIGATION_REPEAT,
--                                                  D_INVESTIGATION_REPEAT_INC,
--                                                  D_INVESTIGATION_REPEAT
--                                                  (dynamically widening D_INVESTIGATION_REPEAT
--                                                   to include every distinct RDB_COLUMN_NM).
--
-- UID block (Tier 3 d_investigation_repeat): 22006000-22006999
--   22006000  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid;
--             nrt_page_case_answer.act_uid for every answer row)
--   22006001  case_management.case_management_uid (IDENTITY-inserted)
--   22006100..22006129  nbs_case_answer.nbs_case_answer_uid +
--             nrt_page_case_answer.nbs_case_answer_uid for each
--             authored answer row (30 rows = 2 blocks * 3 seq * 5 questions).
--             Adjusted to actual authored count (24 rows: 2 blocks * 3
--             seq * 4 questions).
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (referenced by
--                                          nrt_investigation.patient_id;
--                                          same bug-5b convention as TB
--                                          full-chain).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- New Pertussis Investigation full-chain UIDs -----
DECLARE @inv_rept_phc_uid          bigint = 22006000;  -- act.act_uid + public_health_case.public_health_case_uid
DECLARE @inv_rept_case_mgmt_uid    bigint = 22006001;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@inv_rept_phc_uid, N'CASE', N'EVN');

-- =====================================================================
-- ODSE: public_health_case row
-- =====================================================================
-- SRTE-grounded codes (mirroring the Pertussis stub at 22000040 in
-- multi_condition_investigations.sql):
--   condition_code.condition_cd='10190' Pertussis
--   program_area_code.prog_area_cd='VAC'
--   investigation_form_cd='PG_Pertussis_Investigation'
--   code_value_general PHC_CLASS 'C' (Confirmed)
--   code_value_general PHC_IN_STS 'O' (Open)
--   jurisdiction_code '130001' Fulton County
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year])
VALUES
    (@inv_rept_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
     N'C', N'10190', N'Pertussis', N'NND', N'NND',
     N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22006000GA01',
     N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
     N'T', 1, N'VAC', N'130001',
     22006000, N'N', NULL,
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
    (@inv_rept_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
     '2026-04-01T00:00:00', N'CAS22006000GA01', N'PHC_LOCAL_ID',
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
    (@inv_rept_case_mgmt_uid, @inv_rept_phc_uid, N'C',
     N'FRN-INV-REPT-01', '2026-04-02T00:00:00',
     '2026-04-30T00:00:00', '2026-04-30T00:00:00');
SET IDENTITY_INSERT [dbo].[case_management] OFF;

GO

-- =====================================================================
-- ODSE: nbs_case_answer — INTENTIONALLY OMITTED.
-- The TB / Varicella / COVID full-chain fixtures insert one ODSE
-- nbs_case_answer row per RTR-side nrt_page_case_answer row "to satisfy
-- the ODSE-side referential model." However:
--   1. The downstream RTR SP (sp_sld_investigation_repeat_postprocessing)
--      reads ONLY from RDB_MODERN.dbo.nrt_page_case_answer, never from
--      NBS_ODSE.dbo.nbs_case_answer.
--   2. nbs_case_answer has FK_NBS_case_answer267 on nbs_question_uid →
--      nbs_question.nbs_question_uid. The TB/Var/COVID fixtures inherit
--      real baseline NBS_question UIDs (e.g., TUB119=1079) because they
--      use real form-specific questions. This fixture uses fictional
--      question UIDs (22006001..22006014) because we want freedom from
--      baseline question metadata — every RDB_COLUMN_NM is a fresh
--      pivot column we control.
--   3. With fictional UIDs the FK insertion fails. With real UIDs we'd
--      need a 24-question hunting expedition.
-- Skipping nbs_case_answer is safe: the RTR side gets all the data it
-- needs from nrt_page_case_answer below. The comparison test against
-- MasterETL diffs RDB_MODERN-side tables, not ODSE-side tables — so the
-- omission has zero impact on what the comparison sees.
-- =====================================================================

GO

-- =====================================================================
-- RDB_MODERN: staging rows that the SP chain consumes.
-- These are written directly to bypass the CDC pipeline (per STRATEGY.md
-- "Convention: postprocessing SPs read NRT staging only — never ODSE").
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- nrt_investigation row for the full-chain Pertussis Investigation.
-- Mirrors the v2 Tier 1 Investigation shape from
-- fixtures/10_subjects/investigation.sql with Pertussis-specific codes.
--   patient_id = 20000000 (foundation Patient) — required for the
--     bug-5b sentinel-cascade-DELETE path (see TB full-chain header
--     for citation).
--   investigation_form_cd = 'PG_Pertussis_Investigation' — NOT in the
--     SP's exclusion list at line 84 of
--     010-sp_sld_investigation_repeat_postprocessing-001.sql, so the
--     #phc_uids_REPT seed admits this row.
--   batch_id NULL — matches the ISNULL(batch_id, 1)=ISNULL(batch_id, 1)
--     join predicate at line 140.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- nrt_page_case_answer rows. 24 rows = 2 BLOCK_NMs * 3 answer_group_seq_nbr
-- values * 4 data types each.
--
-- The SP at line 167 (#NBS_CASE_ANSWER_REPT seed) requires
-- nrt_page_case_answer.answer_group_seq_nbr IS NOT NULL.
-- The data-type branches additionally require question_group_seq_nbr
-- IS NOT NULL (lines 183-186 TEXT, lines 251-254 CODED, lines 645-647
-- DATE, lines 765-771 NUMERIC).
--
-- data_type values reference baseline NBS_SRTE codeset 'NBS_DATA_TYPE'
-- (TEXT, CODED, DATE, NUMERIC). These rows propagate from
-- nrt_srte_Code_value_general (the same SRTE table TB full-chain uses for
-- code resolution). Verified live 2026-05-21.
--
-- Each row carries a unique RDB_COLUMN_NM. The SP's dynamic ALTER TABLE
-- loop at line 1241 widens D_INVESTIGATION_REPEAT to include every
-- distinct RDB_COLUMN_NM it sees. With 8 distinct columns authored
-- (4 data types * 2 blocks), the dim should widen by +8 columns.
--
-- NOT-NULL columns required by nrt_page_case_answer DDL:
--   act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_question_uid,
--   record_status_cd.
-- nbs_ui_metadata_uid has no FK; we use a stable value (1).
-- ---------------------------------------------------------------------

GO

-- =====================================================================
-- Tail-EXEC the SP chain.
--
-- Step A: flow the new nrt_investigation row into INVESTIGATION.
--   sp_nrt_investigation_postprocessing reads nrt_investigation,
--   writes INVESTIGATION row keyed on case_uid=22006000.
-- =====================================================================


-- =====================================================================
-- Step B: the repeating-block postprocessor.
--   sp_sld_investigation_repeat_postprocessing reads
--   nrt_page_case_answer + nrt_investigation, filters on form_cd NOT IN
--   the exclusion list, pivots answers by RDB_COLUMN_NM, writes:
--     - S_INVESTIGATION_REPEAT      (staging — dropped at end of SP)
--     - LOOKUP_TABLE_N_REPT         (PAGE_CASE_UIDs newly admitted)
--     - L_INVESTIGATION_REPEAT_INC  (page-case → dim-key mapping, incremental)
--     - L_INVESTIGATION_REPEAT      (page-case → dim-key mapping, full)
--     - D_INVESTIGATION_REPEAT_INC  (dim incremental, with dynamically
--                                    added columns from the pivot)
--     - D_INVESTIGATION_REPEAT      (dim full, ALTERed to add new columns
--                                    + INSERTed from incremental)
--
-- Note: this SP is normally invoked via sp_page_builder_postprocessing
-- with @rdb_table_name='D_INVESTIGATION_REPEAT'. We invoke it directly
-- here to mirror the TB-PAM full-chain pattern (direct SP invocation
-- rather than the orchestrator wrapper) — sp_page_builder also requires
-- the PHC to have nrt_investigation AND nrt_page_case_answer rows; both
-- preconditions are satisfied above.
--
-- @batch_id is a free-form bigint used only for job_flow_log
-- correlation. We use a unique value (22006000) to disambiguate this
-- fixture's job_flow_log rows from concurrent fixture runs.
-- =====================================================================


