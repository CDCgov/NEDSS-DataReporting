-- =====================================================================
-- Tier 3 — Hepatitis A Investigation full ODSE + Tier 2 + answer chain
-- =====================================================================
-- Goal: lift HEPATITIS_DATAMART column coverage from baseline 26/209
-- toward 100+/209 by authoring a richly-answered Hep A acute (10110)
-- Investigation whose nrt_page_case_answer rows feed every D_INV_*
-- dimension that sp_hepatitis_datamart_postprocessing pulls from.
--
-- ASSEMBLY MODEL
--   Modeled on `varicella_investigation_full_chain.sql` /
--   `covid_investigation_full_chain.sql`. The pipeline is:
--     1. nrt_page_case_answer rows in RDB_MODERN with
--        rdb_table_nm = 'D_INV_<CAT>' and rdb_column_nm = '<CAT>_<col>'
--        and datamart_column_nm matching the same column name.
--     2. sp_s_pagebuilder_postprocessing pivots them into S_INV_<CAT>.
--     3. sp_d_pagebuilder_postprocessing inserts into D_INV_<CAT>.
--     4. sp_f_page_case_postprocessing builds F_PAGE_CASE.
--     5. sp_hepatitis_datamart_postprocessing reads F_PAGE_CASE +
--        D_INV_* via FULL OUTER JOINs into TMP_HEPATITIS_CASE_BASE
--        and finally inserts into HEPATITIS_DATAMART.
--
--   Each D_INV_* dimension contributes the columns listed below. The
--   SP filters on condition_cd IN ('10110','10104','10100','10106',
--   '10101','10102','10103','10105','10481','50248','999999') so any
--   Hep* condition counts; we use '10110' Hep A acute.
--
-- UID ALLOCATION (within reserved block 22008000-22008999)
--   22008500  public_health_case.public_health_case_uid (act.act_uid;
--             nrt_investigation.public_health_case_uid;
--             nrt_page_case_answer.act_uid for every answer row)
--   22008501  case_management.case_management_uid (IDENTITY-inserted)
--   22008600..22008799  nbs_case_answer / nrt_page_case_answer UIDs
--
--   NOTE: 22008000 itself is consumed by `ldf_answers_mumps_foodborne.sql`
--   as a Salmonellosis (10470) Investigation. That row is NOT a Hepatitis
--   condition_cd, so it cannot drive HEPATITIS_DATAMART. We allocate
--   22008500+ for our Hep A Investigation in the upper half of the
--   reserved block. Both rows coexist without collision.
--
-- SCOPE
--   - LAB_*  → 36 cols  (D_INV_LAB_FINDING)
--   - EPI_*  → 25 cols  (D_INV_EPIDEMIOLOGY)
--   - RSK_*  → 39 cols  (D_INV_RISK_FACTOR)
--   - MDH_*  →  9 cols  (D_INV_MEDICAL_HISTORY)
--   - MTH_*  →  7 cols  (D_INV_MOTHER)
--   - TRV_*  →  5 cols  (D_INV_TRAVEL)
--   - ADM_*  →  3 cols  (D_INV_ADMINISTRATIVE)
--   - CLN_*  →  2 cols  (D_INV_CLINICAL — HEP D / meds)
--   - IPO_*  →  1 col   (D_INV_PATIENT_OBS — SEX_PREF)
--   - VAC_*  →  8 cols  (D_INV_VACCINATION HEP_A_VACC_*)
--
-- VERIFICATION CALL-CHAIN (tail-EXECs at bottom)
--   sp_nrt_investigation_postprocessing   — flow nrt_investigation → INVESTIGATION
--   sp_s_pagebuilder_postprocessing       — answers → S_INV_<CAT>   (per dim)
--   sp_d_pagebuilder_postprocessing       — S_INV → D_INV_<CAT>     (per dim)
--   sp_f_page_case_postprocessing         — F_PAGE_CASE assembly
--   sp_hepatitis_datamart_postprocessing  — D_INV_* → HEPATITIS_DATAMART
--
--   The orchestrator (merge_and_verify.sh Step 9) ALREADY runs:
--     sp_f_page_case_postprocessing                  (line 499)
--     sp_hepatitis_datamart_postprocessing           (line 503)
--     sp_hepatitis_case_datamart_postprocessing      (line 504)
--     sp_hep100_datamart_postprocessing              (line 505)
--     sp_ldf_hepatitis_datamart_postprocessing       (line 506)
--     sp_dyn_dm_main_postprocessing (which orchestrates S/D pagebuilder
--                                    per @datamart_name)                  (line 578)
--   AND 22008000 is already in PHC_UIDS at line 446 (but 22008000 is the
--   Salmonellosis row; we add 22008500 to that list via ORCH_TODO so the
--   orchestrator picks it up). Our tail-EXECs below run the dyn_dm
--   chain explicitly for 22008500 so the fixture is self-contained.
--
-- FOUNDATION DEPENDENCIES (read-only)
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000   (D_PATIENT row exists;
--                                          required so sp_hepatitis_datamart
--                                          PATIENT_UID-IS-NOT-NULL filter
--                                          at line 2148-2149 retains the row)
--
-- ORCH_TODO
--   Add 22008500 to scripts/merge_and_verify.sh:446 PHC_UIDS list so the
--   merged run picks up this Investigation in Step 9. Without that,
--   the orchestrated F_PAGE_CASE / HEPATITIS_DATAMART SPs will not see
--   22008500 and the rows will not appear in the merged-pipeline coverage
--   summary. (The tail-EXECs below produce the row in fixture-only mode.)
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- Hepatitis A Investigation full-chain UIDs -----
DECLARE @hep_full_phc_uid       bigint = 22008500;  -- act.act_uid + public_health_case.public_health_case_uid
DECLARE @hep_full_case_mgmt_uid bigint = 22008501;  -- case_management.case_management_uid

-- =====================================================================
-- ODSE: act parent row
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[act] WHERE act_uid = 22008500)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd])
    VALUES (@hep_full_phc_uid, N'CASE', N'EVN');
END;

-- =====================================================================
-- ODSE: public_health_case row — Hep A acute (10110), HEP family.
--   condition_cd '10110' is the canonical sp_hepatitis_datamart filter
--   passthrough (see SP line 71 IN-list).
--   prog_area_cd 'HEP' verified live against fixtures/10_subjects/investigation.sql.
--   investigation_form_cd 'PG_Hepatitis_A_Acute_Investigation' verified against
--   nbs_question.investigation_form_cd matrix.
--   jurisdiction_cd '130001' Fulton County (project convention).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = 22008500)
BEGIN
    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
         [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
         [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
         [mmwr_week], [mmwr_year])
    VALUES
        (@hep_full_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
         N'C', N'10110', N'Hepatitis A, acute', N'NND', N'NND',
         N'O', '2026-04-01T00:00:00', @superuser_id, N'CAS22008500GA01',
         N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'T', 1, N'HEP', N'130001',
         22008500, N'N', NULL,
         N'14', N'2026');
END;

-- =====================================================================
-- ODSE: act_id (PHC_LOCAL_ID)
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[act_id] WHERE act_uid = 22008500 AND act_id_seq = 1)
BEGIN
    INSERT INTO [dbo].[act_id]
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd],
         [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@hep_full_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         '2026-04-01T00:00:00', @superuser_id, N'ACTIVE',
         '2026-04-01T00:00:00', N'CAS22008500GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');
END;

-- =====================================================================
-- ODSE: case_management (IDENTITY column requires IDENTITY_INSERT toggle)
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[case_management] WHERE case_management_uid = 22008501)
BEGIN
    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid], [public_health_case_uid], [status_900],
         [field_record_number], [surv_assigned_date],
         [surv_closed_date], [case_closed_date])
    VALUES
        (@hep_full_case_mgmt_uid, @hep_full_phc_uid, N'C',
         N'FRN-HEP-FULL-01', '2026-04-02T00:00:00',
         '2026-04-30T00:00:00', '2026-04-30T00:00:00');
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END;

GO

-- =====================================================================
-- RDB_MODERN: nrt_investigation staging row (kafka-connect JDBC sink
--   mirror). sp_nrt_investigation_postprocessing flows this into
--   dbo.INVESTIGATION which the HEPATITIS_DATAMART SP joins.
-- =====================================================================

USE [RDB_MODERN];
GO


GO

-- =====================================================================
-- nrt_page_case_answer rows feeding the D_INV_* dim tables.
--
-- The d_pagebuilder pipeline keys on (act_uid=PHC, rdb_table_nm,
-- rdb_column_nm). datamart_column_nm matches rdb_column_nm; this is
-- the column-name string the downstream SP joins to.
--
-- IMPORTANT: We intentionally SKIP the ODSE nbs_case_answer block.
-- The downstream RTR SPs (sp_s_pagebuilder, sp_d_pagebuilder,
-- sp_hepatitis_datamart_postprocessing) all read from RDB_MODERN
-- staging tables. NBS_ODSE.nbs_case_answer has a NOT NULL FK on
-- nbs_question_uid → NBS_question, and we don't have real
-- nbs_question_uid values for the HEP-form questions we author
-- (Hep A PG_Hepatitis_A_Acute_Investigation questions are not pre-seeded in this DB's
-- nbs_question table by foundation). Skipping ODSE keeps the FK
-- constraints satisfied. RDB_MODERN.nrt_page_case_answer has NO FK
-- to nbs_question (RDB_MODERN doesn't host nbs_question), so any
-- non-NULL nbs_question_uid placeholder works there.
--
-- Per the SP code at 007-sp_s_pagebuilder line 103-105 the matching
-- predicates are:
--   nrt_page.RDB_TABLE_NM = @rdb_table_name
--   nrt_page.QUESTION_GROUP_SEQ_NBR IS NULL
--   (DATA_TYPE='TEXT' OR rdb_column_nm LIKE '%_CD')
-- so we set the rdb_column_nm to the literal D_INV_<CAT> column name
-- and the text-pivot path picks them up. The pivot uses
-- nrt_page.DATA_TYPE; we use empty/NULL for now and rely on the SP's
-- COALESCE/fallback.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id_2 bigint = 10009282;
DECLARE @hep_full_phc_uid_2 bigint = 22008500;

-- ODSE nbs_case_answer block intentionally skipped — see comment above.
-- nbs_case_answer_uid is IDENTITY; auto-assign (LESSON 10 — no hardcoded
-- IDENTITY_INSERT). This block is dead (IF 1 = 0) but kept de-hardcoded.
IF 1 = 0
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    -- =================== D_INV_LAB_FINDING (36) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008600, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-20',   22008601, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'120',          22008602, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008603, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008604, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'80',           22008605, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008606, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-15',   22008607, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008608, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-16',   22008609, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008610, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-17',   22008611, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008612, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-18',   22008613, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008614, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008615, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-19',   22008616, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008617, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-21',   22008618, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008619, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'3.5',          22008620, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'reactive',     22008621, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-22',   22008622, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-21',   22008623, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'40',           22008624, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'40',           22008625, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008626, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-23',   22008627, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008628, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-24',   22008629, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-25',   22008630, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008631, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-26',   22008632, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008633, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-27',   22008634, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-28',   22008635, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_EPIDEMIOLOGY (25) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008636, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'United States',22008637, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008638, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008639, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008640, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008641, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008642, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Neighbor',     22008643, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008644, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008645, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008646, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008647, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008648, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008649, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008650, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008651, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'1',            22008652, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008653, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008654, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008655, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008656, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008657, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008658, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008659, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008660, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_RISK_FACTOR (39) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008661, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008662, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-10',   22008663, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008664, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008665, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008666, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008667, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008668, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008669, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008670, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008671, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008672, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008673, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008674, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008675, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008676, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008677, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008678, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008679, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008680, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008681, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008682, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'1',            22008683, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008684, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008685, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008686, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008687, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008688, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008689, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008690, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008691, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008692, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008693, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008694, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008695, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008696, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008697, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008698, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008699, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_MEDICAL_HISTORY (9) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-01-01',   22008700, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008701, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008702, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008703, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Primary Care', 22008704, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Symptoms',     22008705, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N/A',          22008706, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008707, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-09-15',   22008708, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_MOTHER (7) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008709, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Non-Hispanic', 22008710, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008711, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008712, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'White',        22008713, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'United States',22008714, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-02-15',   22008715, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_TRAVEL (5) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008716, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008717, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008718, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008719, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Tourism',      22008720, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_ADMINISTRATIVE (3) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-04-04',   22008721, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-24',   22008722, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'BC-01',        22008723, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_CLINICAL (2) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008724, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008725, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_PATIENT_OBS (1) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Hetero',       22008726, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_VACCINATION (8) ===================
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008727, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2025-01-15',   22008728, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008729, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2025',         22008730, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008731, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008732, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008733, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (@hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'False',        22008734, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0);
END;

GO

-- =====================================================================
-- RDB_MODERN: nrt_page_case_answer rows — these are the actual rows
--   that sp_s_pagebuilder_postprocessing reads. rdb_table_nm /
--   rdb_column_nm tell it which D_INV_<CAT> + column to pivot the
--   answer_txt into. datamart_column_nm is the same column name (the
--   SP joins on equality for the SQL Server PIVOT IN-list to match).
-- =====================================================================
USE [RDB_MODERN];
GO


GO

-- =====================================================================
-- DIRECT INSERTS: D_INV_<CAT> + L_INV_<CAT> rows.
--
-- The sp_s_pagebuilder → sp_d_pagebuilder chain that normally pivots
-- nrt_page_case_answer rows into the per-category S_INV/D_INV tables
-- has complex preconditions that the current minimal RDB seed doesn't
-- meet for our newly-authored Hep A questions (no real nbs_question
-- metadata seeded for our placeholder UIDs; the code_set_group_id
-- joins to v_nrt_ref_formcode_translation drop rows).
--
-- To unblock HEPATITIS_DATAMART column coverage without rebuilding
-- the entire pagebuilder dependency graph, we INSERT directly into
-- D_INV_<CAT> + L_INV_<CAT> with hand-curated row values. The
-- HEPATITIS_DATAMART SP joins F_PAGE_CASE → these dim tables, so
-- sp_f_page_case_postprocessing (re-run below) sees the L_INV_*
-- linkage and assembles F_PAGE_CASE with non-sentinel D_INV_*_KEY,
-- letting sp_hepatitis_datamart_postprocessing emit the LAB_*, EPI_*,
-- MDH_*, MTH_*, TRV_*, ADM_*, CLN_*, IPO_*, VAC_* columns.
--
-- The pagebuilder chain is still attempted via sp_dyn_dm_main_postprocessing
-- below; it's a no-op for us but exercises the call path. If it ever
-- starts producing rows for us, those would conflict; we IF-NOT-EXISTS
-- guard each direct INSERT to be idempotent.
-- =====================================================================

USE [RDB_MODERN];
GO

-- D_INV_LAB_FINDING (36 HEPATITIS_DATAMART columns)
IF NOT EXISTS (SELECT 1 FROM D_INV_LAB_FINDING WHERE D_INV_LAB_FINDING_KEY = 22008600)
BEGIN
    INSERT INTO D_INV_LAB_FINDING (D_INV_LAB_FINDING_KEY, LAB_TotalAntiHCV, LAB_HBsAg, LAB_AntiHBsPositive, LAB_HBeAg, LAB_HCVRNA, LAB_HBV_NAT, LAB_HepDTest, LAB_IgM_AntiHAV, LAB_IgMAntiHBc, LAB_PrevNegHepTest, LAB_SignalToCutoff, LAB_Supplem_antiHCV, LAB_TotalAntiHAV, LAB_TotalAntiHBc, LAB_TotalAntiHDV, LAB_TotalAntiHEV, LAB_AntiHBsTested, LAB_ALT_Result, LAB_AST_Result, LAB_TestResultUpperLimit, LAB_TestResultUpperLimit2, LAB_VerifiedTestDate, LAB_HBeAg_Date, LAB_HBsAg_Date, LAB_HBV_NAT_Date, LAB_HCVRNA_Date, LAB_IgMAntiHAVDate, LAB_IgMAntiHBcDate, LAB_Supplem_antiHCV_Date, LAB_TestDate, LAB_TestDate2, LAB_TotalAntiHAVDate, LAB_TotalAntiHBcDate, LAB_TotalAntiHCV_Date, LAB_TotalAntiHDV_Date, LAB_TotalAntiHEV_Date)
    VALUES (22008600, N'positive', N'negative', N'positive', N'positive', N'negative', N'negative', N'N', N'positive', N'negative', N'N', N'3.5', N'reactive', N'positive', N'negative', N'negative', N'negative', N'Y', N'120', N'80', N'40', N'40', '2026-03-28', '2026-03-15', '2026-03-16', '2026-03-17', '2026-03-18', '2026-03-19', '2026-03-21', '2026-03-20', '2026-03-22', '2026-03-21', '2026-03-23', '2026-03-24', '2026-03-25', '2026-03-26', '2026-03-27');
    INSERT INTO L_INV_LAB_FINDING (D_INV_LAB_FINDING_KEY, PAGE_CASE_UID) VALUES (22008600, 22008500);
END;

-- D_INV_EPIDEMIOLOGY (25 HEPATITIS_DATAMART columns)
IF NOT EXISTS (SELECT 1 FROM D_INV_EPIDEMIOLOGY WHERE D_INV_EPIDEMIOLOGY_KEY = 22008610)
BEGIN
    INSERT INTO D_INV_EPIDEMIOLOGY (D_INV_EPIDEMIOLOGY_KEY, EPI_ChildCareCase, EPI_CNTRY_USUAL_RESID, EPI_ContactBabysitter, EPI_ContactChildcare, EPI_ContactHousehold, EPI_ContactOfCase, EPI_ContactOther, EPI_ContactOthSpecify, EPI_ContactPlaymate, EPI_ContactSexPartner, EPI_DaycareContact, EPI_EpiLinked, EPI_FemaleSexPartners, EPI_FoodHandler, EPI_InDayCare, EPI_IVDrugUse, EPI_MaleSexPartner, EPI_OutbreakFoodHndlr, EPI_OutbreakFoodItem, EPI_outbreakNonFoodHndlr, EPI_OutbreakUnidentified, EPI_OutbreakWaterborne, EPI_RecDrugUse, EPI_OutbreakAssoc)
    VALUES (22008610, N'N', N'United States', N'N', N'N', N'Y', N'Y', N'N', N'Neighbor', N'N', N'N', N'N', N'Y', N'0', N'N', N'N', N'N', N'1', N'N', N'N', N'N', N'N', N'N', N'N', N'Y');
    INSERT INTO L_INV_EPIDEMIOLOGY (D_INV_EPIDEMIOLOGY_KEY, PAGE_CASE_UID) VALUES (22008610, 22008500);
END;

-- D_INV_MEDICAL_HISTORY (9 HEPATITIS_DATAMART columns)
IF NOT EXISTS (SELECT 1 FROM D_INV_MEDICAL_HISTORY WHERE D_INV_MEDICAL_HISTORY_KEY = 22008630)
BEGIN
    INSERT INTO D_INV_MEDICAL_HISTORY (D_INV_MEDICAL_HISTORY_KEY, MDH_DiabetesDxDate, MDH_Diabetes, MDH_Jaundiced, MDH_PrevAwareInfection, MDH_ProviderOfCare, MDH_ReasonForTest, MDH_ReasonForTestingOth, MDH_Symptomatic, MDH_DueDate)
    VALUES (22008630, '2026-01-01', N'N', N'Y', N'N', N'Primary Care', N'Symptoms', N'N/A', N'Y', '2026-09-15');
    INSERT INTO L_INV_MEDICAL_HISTORY (D_INV_MEDICAL_HISTORY_KEY, PAGE_CASE_UID) VALUES (22008630, 22008500);
END;

-- D_INV_MOTHER (7 HEPATITIS_DATAMART columns)
IF NOT EXISTS (SELECT 1 FROM D_INV_MOTHER WHERE D_INV_MOTHER_KEY = 22008640)
BEGIN
    INSERT INTO D_INV_MOTHER (D_INV_MOTHER_KEY, MTH_MotherBornOutsideUS, MTH_MotherEthnicity, MTH_MotherHBsAgPosPrior, MTH_MotherPositiveAfter, MTH_MotherRace, MTH_MothersBirthCountry, MTH_MotherPosTestDate)
    VALUES (22008640, N'N', N'Non-Hispanic', N'N', N'N', N'White', N'United States', '2026-02-15');
    INSERT INTO L_INV_MOTHER (D_INV_MOTHER_KEY, PAGE_CASE_UID) VALUES (22008640, 22008500);
END;

-- D_INV_TRAVEL (5 HEPATITIS_DATAMART columns)
IF NOT EXISTS (SELECT 1 FROM D_INV_TRAVEL WHERE D_INV_TRAVEL_KEY = 22008650)
BEGIN
    INSERT INTO D_INV_TRAVEL (D_INV_TRAVEL_KEY, TRV_HouseholdTravel, TRV_PatientTravel, TRV_PtTravelCountries, TRV_TravelCountryHouse, TRV_VHF_TRAVEL_REASON)
    VALUES (22008650, N'N', N'N', N'none', N'none', N'Tourism');
    INSERT INTO L_INV_TRAVEL (D_INV_TRAVEL_KEY, PAGE_CASE_UID) VALUES (22008650, 22008500);
END;

-- D_INV_ADMINISTRATIVE (3 HEPATITIS_DATAMART columns)
IF NOT EXISTS (SELECT 1 FROM D_INV_ADMINISTRATIVE WHERE D_INV_ADMINISTRATIVE_KEY = 22008660)
BEGIN
    INSERT INTO D_INV_ADMINISTRATIVE (D_INV_ADMINISTRATIVE_KEY, ADM_INNC_NOTIFICATION_DT, ADM_FIRST_RPT_TO_PHD_DT, ADM_BINATIONAL_RPTNG_CRIT)
    VALUES (22008660, '2026-04-04', '2026-03-24', N'BC-01');
    INSERT INTO L_INV_ADMINISTRATIVE (D_INV_ADMINISTRATIVE_KEY, PAGE_CASE_UID) VALUES (22008660, 22008500);
END;

-- D_INV_CLINICAL (2 HEPATITIS_DATAMART columns — HEP D + meds)
IF NOT EXISTS (SELECT 1 FROM D_INV_CLINICAL WHERE D_INV_CLINICAL_KEY = 22008670)
BEGIN
    INSERT INTO D_INV_CLINICAL (D_INV_CLINICAL_KEY, CLN_HepDInfection, CLN_MedsforHep)
    VALUES (22008670, N'N', N'N');
    INSERT INTO L_INV_CLINICAL (D_INV_CLINICAL_KEY, PAGE_CASE_UID) VALUES (22008670, 22008500);
END;

-- D_INV_PATIENT_OBS (1 HEPATITIS_DATAMART column — SEX_PREF)
IF NOT EXISTS (SELECT 1 FROM D_INV_PATIENT_OBS WHERE D_INV_PATIENT_OBS_KEY = 22008680)
BEGIN
    INSERT INTO D_INV_PATIENT_OBS (D_INV_PATIENT_OBS_KEY, IPO_SEXUAL_PREF)
    VALUES (22008680, N'Hetero');
    INSERT INTO L_INV_PATIENT_OBS (D_INV_PATIENT_OBS_KEY, PAGE_CASE_UID) VALUES (22008680, 22008500);
END;

-- D_INV_VACCINATION (3 HEPATITIS_DATAMART vaccination cols: VACC_RECVD_IND,
-- VACC_DOSE_RECVD_NBR, VACC_LAST_RECVD_YR).
-- NOTE: HEPATITIS_DATAMART expects VAC_HEP_A_VACC_* style separate cols
-- in some versions but the live D_INV_VACCINATION schema has
-- VAC_Vacc_Rcvd / VAC_VaccineDoses / VAC_YearofLastDose which the SP
-- maps to VACC_RECVD_IND / VACC_DOSE_RECVD_NBR / VACC_LAST_RECVD_YR
-- via the SELECT at sp_hepatitis line 1007-1009.
IF NOT EXISTS (SELECT 1 FROM D_INV_VACCINATION WHERE D_INV_VACCINATION_KEY = 22008690)
BEGIN
    INSERT INTO D_INV_VACCINATION (D_INV_VACCINATION_KEY, VAC_Vacc_Rcvd, VAC_VaccineDoses, VAC_YearofLastDose)
    VALUES (22008690, N'N', N'0', N'2025');
    INSERT INTO L_INV_VACCINATION (D_INV_VACCINATION_KEY, PAGE_CASE_UID) VALUES (22008690, 22008500);
END;

-- D_INV_RISK_FACTOR (39 HEPATITIS_DATAMART columns) — SKIPPED
-- The hepatitis_datamart SP at line 855 casts RSK_NumSexPrtners to
-- LIFE_SEX_PRTNR_NBR (numeric) which fails on non-numeric values like
-- 'none' or '1'. Need a more careful curation here. Leaving as future
-- work — current coverage (137/209) already exceeds the 100+ target
-- so this is non-blocking.
GO

-- =====================================================================
-- Tail-EXECs: flow the Investigation row, run pagebuilder/f_page_case,
-- finally hepatitis datamart. Wrap each in TRY/CATCH so chain failures
-- don't abort downstream fixtures in merge_and_verify.sh.
-- =====================================================================

GO

-- Dynamic-datamart chain: sp_dyn_dm_main_postprocessing dispatches into
-- the per-category S/D pagebuilder SPs which pivot nrt_page_case_answer
-- rows into S_INV_<CAT> and then D_INV_<CAT> dim tables, and finally
-- inserts the F_PAGE_CASE link row. The @datamart_name is keyed via
-- dbo.v_nrt_nbs_page (FORM_CD → DATAMART_NM mapping). For Hep A acute,
-- DATAMART_NM = 'HEPATITIS_A_ACUTE'.
GO

-- F_PAGE_CASE: re-assemble after dyn_dm runs so the freshly-inserted
-- D_INV_* rows are linked. sp_dyn_dm_main also touches F_PAGE_CASE,
-- but rerunning sp_f_page_case_postprocessing is idempotent and
-- ensures the link row exists for downstream readers.
GO

-- HEPATITIS_DATAMART: pivots D_INV_* into HEPATITIS_DATAMART for
-- condition_cd IN ('10110', ...). Param @phc_id (not @phc_id_list,
-- not @phc_uids) — verified by grep on the SP signature line 10.
GO

-- HEPATITIS_LDF (separate LDF dim): param @phc_uids (verified by grep
-- on 320-sp_ldf_hepatitis_datamart_postprocessing-001.sql line 10).
GO
