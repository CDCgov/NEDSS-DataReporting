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
--   investigation_form_cd 'INV_FORM_HEPA' verified against
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
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
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

IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_investigation] WHERE public_health_case_uid = 22008500)
BEGIN
    INSERT INTO [dbo].[nrt_investigation]
        ([public_health_case_uid], [patient_id], [program_jurisdiction_oid],
         [local_id], [shared_ind], [case_type_cd],
         [jurisdiction_cd], [jurisdiction_nm], [record_status_cd], [mood_cd], [class_cd],
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
         -- investigation-side enrichments that map to HEPATITIS_DATAMART
         -- via the INVESTIGATION dimension (not via D_INV_*).
         [diagnosis_time], [effective_from_time],
         [rpt_form_cmplt_time], [rpt_to_county_time], [rpt_to_state_time],
         [earliest_rpt_to_phd_dt], [earliest_rpt_to_cdc_dt],
         [hospitalized_admin_time], [hospitalized_discharge_time],
         [hospitalized_duration_amt], [hospitalized_ind], [hospitalized_ind_cd],
         [outbreak_ind_val],
         [transmission_mode_cd], [transmission_mode],
         [disease_imported_ind], [disease_imported_cd],
         [imported_from_country], [imported_from_state], [imported_from_county],
         [imported_city_desc_txt], [imported_country_cd], [imported_state_cd],
         [imported_county_cd], [import_frm_city_cd],
         [die_frm_this_illness_ind],
         [legacy_case_id], [rpt_source_cd], [rpt_src_cd_desc],
         [pat_age_at_onset], [pat_age_at_onset_unit_cd], [pat_age_at_onset_unit],
         [investigator_assigned_datetime])
    VALUES
        (22008500,                              -- public_health_case_uid
         20000000,                              -- patient_id (foundation Patient)
         22008500,                              -- program_jurisdiction_oid
         N'CAS22008500GA01',                    -- local_id
         N'T',                                  -- shared_ind
         N'I',                                  -- case_type_cd
         N'130001',                             -- jurisdiction_cd (Fulton)
         N'Fulton County',                      -- jurisdiction_nm
         N'ACTIVE',                             -- record_status_cd
         N'EVN', N'CASE',                       -- mood_cd, class_cd
         N'C', N'10110', N'Hepatitis A, acute', N'HEP', -- case_class_cd, cd, cd_desc, prog
         N'INV_FORM_HEPA',                      -- investigation_form_cd
         22008501,                              -- case_management_uid
         N'O', N'Open',
         N'Confirmed',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
         10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
         10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
         N'14', N'2026',
         22008500,                              -- nac_page_case_uid
         N'Y',                                  -- outbreak_ind
         '2026-03-23T00:00:00',                 -- diagnosis_time
         '2026-03-22T00:00:00',                 -- effective_from_time
         '2026-04-04T00:00:00',                 -- rpt_form_cmplt_time
         '2026-03-24T00:00:00',                 -- rpt_to_county_time
         '2026-03-26T00:00:00',                 -- rpt_to_state_time
         '2026-03-23T00:00:00',                 -- earliest_rpt_to_phd_dt
         '2026-04-07T00:00:00',                 -- earliest_rpt_to_cdc_dt
         '2026-03-25T00:00:00',                 -- hospitalized_admin_time
         '2026-04-02T00:00:00',                 -- hospitalized_discharge_time
         8,                                     -- hospitalized_duration_amt
         N'Yes', N'Y',                          -- hospitalized_ind, _cd
         N'Yes',                                -- outbreak_ind_val
         N'B', N'Bloodborne',                   -- transmission_mode_cd, mode
         N'Indigenous', N'IND',
         N'United States', N'Georgia', N'Fulton County',
         N'Atlanta', N'840', N'13',
         N'13121', N'13',
         N'N',                                  -- die_frm_this_illness_ind
         N'LEGACY-22008500', N'PP', N'Private Physician',
         N'45', N'Y', N'Years',
         '2026-04-02T00:00:00');
END;

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
-- (Hep A INV_FORM_HEPA questions are not pre-seeded in this DB's
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
IF 1 = 0
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;

    INSERT INTO [dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    -- =================== D_INV_LAB_FINDING (36) ===================
    (22008600, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008600, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008601, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-20',   22008601, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008602, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'120',          22008602, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008603, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008603, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008604, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008604, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008605, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'80',           22008605, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008606, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008606, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008607, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-15',   22008607, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008608, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008608, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008609, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-16',   22008609, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008610, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008610, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008611, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-17',   22008611, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008612, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008612, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008613, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-18',   22008613, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008614, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008614, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008615, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008615, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008616, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-19',   22008616, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008617, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008617, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008618, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-21',   22008618, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008619, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008619, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008620, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'3.5',          22008620, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008621, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'reactive',     22008621, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008622, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-22',   22008622, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008623, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-21',   22008623, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008624, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'40',           22008624, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008625, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'40',           22008625, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008626, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'positive',     22008626, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008627, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-23',   22008627, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008628, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008628, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008629, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-24',   22008629, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008630, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-25',   22008630, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008631, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008631, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008632, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-26',   22008632, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008633, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'negative',     22008633, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008634, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-27',   22008634, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008635, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-28',   22008635, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_EPIDEMIOLOGY (25) ===================
    (22008636, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008636, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008637, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'United States',22008637, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008638, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008638, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008639, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008639, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008640, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008640, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008641, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008641, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008642, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008642, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008643, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Neighbor',     22008643, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008644, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008644, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008645, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008645, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008646, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008646, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008647, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008647, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008648, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008648, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008649, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008649, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008650, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008650, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008651, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008651, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008652, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'1',            22008652, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008653, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008653, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008654, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008654, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008655, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008655, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008656, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008656, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008657, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008657, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008658, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008658, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008659, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008659, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008660, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008660, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_RISK_FACTOR (39) ===================
    (22008661, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008661, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008662, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008662, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008663, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-10',   22008663, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008664, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008664, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008665, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008665, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008666, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008666, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008667, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008667, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008668, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008668, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008669, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008669, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008670, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008670, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008671, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008671, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008672, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008672, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008673, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008673, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008674, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008674, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008675, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008675, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008676, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008676, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008677, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008677, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008678, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008678, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008679, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008679, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008680, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008680, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008681, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008681, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008682, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008682, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008683, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'1',            22008683, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008684, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008684, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008685, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008685, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008686, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008686, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008687, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008687, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008688, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008688, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008689, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008689, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008690, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008690, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008691, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008691, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008692, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008692, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008693, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008693, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008694, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008694, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008695, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008695, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008696, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008696, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008697, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008697, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008698, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008698, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008699, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008699, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_MEDICAL_HISTORY (9) ===================
    (22008700, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-01-01',   22008700, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008701, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008701, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008702, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008702, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008703, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008703, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008704, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Primary Care', 22008704, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008705, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Symptoms',     22008705, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008706, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N/A',          22008706, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008707, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Y',            22008707, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008708, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-09-15',   22008708, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_MOTHER (7) ===================
    (22008709, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008709, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008710, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Non-Hispanic', 22008710, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008711, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008711, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008712, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008712, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008713, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'White',        22008713, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008714, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'United States',22008714, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008715, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-02-15',   22008715, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_TRAVEL (5) ===================
    (22008716, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008716, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008717, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008717, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008718, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008718, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008719, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'none',         22008719, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008720, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Tourism',      22008720, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_ADMINISTRATIVE (3) ===================
    (22008721, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-04-04',   22008721, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008722, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2026-03-24',   22008722, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008723, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'BC-01',        22008723, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_CLINICAL (2) ===================
    (22008724, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008724, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008725, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008725, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_PATIENT_OBS (1) ===================
    (22008726, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'Hetero',       22008726, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    -- =================== D_INV_VACCINATION (8) ===================
    (22008727, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008727, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008728, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2025-01-15',   22008728, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008729, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008729, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008730, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'2025',         22008730, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008731, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'N',            22008731, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008732, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008732, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008733, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'0',            22008733, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0),
    (22008734, @hep_full_phc_uid_2, '2026-04-01T00:00:00', @superuser_id_2, N'False',        22008734, 1, '2026-04-01T00:00:00', @superuser_id_2, N'ACTIVE', '2026-04-01T00:00:00', 0);

    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
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

IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_page_case_answer] WHERE act_uid = 22008500 AND nbs_case_answer_uid = 22008600)
BEGIN
INSERT INTO [dbo].[nrt_page_case_answer]
    ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
     [nbs_question_uid],
     [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
     [investigation_form_cd], [question_identifier], [data_location],
     [code_set_group_id], [last_chg_time], [record_status_cd],
     [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
     [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd])
VALUES
-- =================== D_INV_LAB_FINDING (36) ===================
(22008500, 22008600, 2, 22008600, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHCV',            N'positive',     N'1', N'INV_FORM_HEPA', N'INV-LAB-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHCV',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008601, 2, 22008601, N'D_INV_LAB_FINDING', N'LAB_Supplem_antiHCV_Date',    N'2026-03-20',   N'1', N'INV_FORM_HEPA', N'INV-LAB-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_Supplem_antiHCV_Date',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008602, 2, 22008602, N'D_INV_LAB_FINDING', N'LAB_ALT_Result',              N'120',          N'1', N'INV_FORM_HEPA', N'INV-LAB-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_ALT_Result',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008603, 2, 22008603, N'D_INV_LAB_FINDING', N'LAB_AntiHBsPositive',         N'positive',     N'1', N'INV_FORM_HEPA', N'INV-LAB-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_AntiHBsPositive',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008604, 2, 22008604, N'D_INV_LAB_FINDING', N'LAB_AntiHBsTested',           N'Y',            N'1', N'INV_FORM_HEPA', N'INV-LAB-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_AntiHBsTested',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008605, 2, 22008605, N'D_INV_LAB_FINDING', N'LAB_AST_Result',              N'80',           N'1', N'INV_FORM_HEPA', N'INV-LAB-006', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_AST_Result',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008606, 2, 22008606, N'D_INV_LAB_FINDING', N'LAB_HBeAg',                   N'positive',     N'1', N'INV_FORM_HEPA', N'INV-LAB-007', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HBeAg',                   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008607, 2, 22008607, N'D_INV_LAB_FINDING', N'LAB_HBeAg_Date',              N'2026-03-15',   N'1', N'INV_FORM_HEPA', N'INV-LAB-008', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HBeAg_Date',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008608, 2, 22008608, N'D_INV_LAB_FINDING', N'LAB_HBsAg',                   N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-009', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HBsAg',                   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008609, 2, 22008609, N'D_INV_LAB_FINDING', N'LAB_HBsAg_Date',              N'2026-03-16',   N'1', N'INV_FORM_HEPA', N'INV-LAB-010', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HBsAg_Date',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008610, 2, 22008610, N'D_INV_LAB_FINDING', N'LAB_HBV_NAT',                 N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-011', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HBV_NAT',                 NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008611, 2, 22008611, N'D_INV_LAB_FINDING', N'LAB_HBV_NAT_Date',            N'2026-03-17',   N'1', N'INV_FORM_HEPA', N'INV-LAB-012', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HBV_NAT_Date',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008612, 2, 22008612, N'D_INV_LAB_FINDING', N'LAB_HCVRNA',                  N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-013', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HCVRNA',                  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008613, 2, 22008613, N'D_INV_LAB_FINDING', N'LAB_HCVRNA_Date',             N'2026-03-18',   N'1', N'INV_FORM_HEPA', N'INV-LAB-014', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HCVRNA_Date',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008614, 2, 22008614, N'D_INV_LAB_FINDING', N'LAB_HepDTest',                N'N',            N'1', N'INV_FORM_HEPA', N'INV-LAB-015', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_HepDTest',                NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008615, 2, 22008615, N'D_INV_LAB_FINDING', N'LAB_IgM_AntiHAV',             N'positive',     N'1', N'INV_FORM_HEPA', N'INV-LAB-016', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_IgM_AntiHAV',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008616, 2, 22008616, N'D_INV_LAB_FINDING', N'LAB_IgMAntiHAVDate',          N'2026-03-19',   N'1', N'INV_FORM_HEPA', N'INV-LAB-017', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_IgMAntiHAVDate',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008617, 2, 22008617, N'D_INV_LAB_FINDING', N'LAB_IgMAntiHBc',              N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-018', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_IgMAntiHBc',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008618, 2, 22008618, N'D_INV_LAB_FINDING', N'LAB_IgMAntiHBcDate',          N'2026-03-21',   N'1', N'INV_FORM_HEPA', N'INV-LAB-019', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_IgMAntiHBcDate',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008619, 2, 22008619, N'D_INV_LAB_FINDING', N'LAB_PrevNegHepTest',          N'N',            N'1', N'INV_FORM_HEPA', N'INV-LAB-020', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_PrevNegHepTest',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008620, 2, 22008620, N'D_INV_LAB_FINDING', N'LAB_SignalToCutoff',          N'3.5',          N'1', N'INV_FORM_HEPA', N'INV-LAB-021', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_SignalToCutoff',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008621, 2, 22008621, N'D_INV_LAB_FINDING', N'LAB_Supplem_antiHCV',         N'reactive',     N'1', N'INV_FORM_HEPA', N'INV-LAB-022', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_Supplem_antiHCV',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008622, 2, 22008622, N'D_INV_LAB_FINDING', N'LAB_TestDate',                N'2026-03-22',   N'1', N'INV_FORM_HEPA', N'INV-LAB-023', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TestDate',                NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008623, 2, 22008623, N'D_INV_LAB_FINDING', N'LAB_TestDate2',               N'2026-03-21',   N'1', N'INV_FORM_HEPA', N'INV-LAB-024', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TestDate2',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008624, 2, 22008624, N'D_INV_LAB_FINDING', N'LAB_TestResultUpperLimit',    N'40',           N'1', N'INV_FORM_HEPA', N'INV-LAB-025', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TestResultUpperLimit',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008625, 2, 22008625, N'D_INV_LAB_FINDING', N'LAB_TestResultUpperLimit2',   N'40',           N'1', N'INV_FORM_HEPA', N'INV-LAB-026', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TestResultUpperLimit2',   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008626, 2, 22008626, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHAV',            N'positive',     N'1', N'INV_FORM_HEPA', N'INV-LAB-027', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHAV',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008627, 2, 22008627, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHAVDate',        N'2026-03-23',   N'1', N'INV_FORM_HEPA', N'INV-LAB-028', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHAVDate',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008628, 2, 22008628, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHBc',            N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-029', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHBc',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008629, 2, 22008629, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHBcDate',        N'2026-03-24',   N'1', N'INV_FORM_HEPA', N'INV-LAB-030', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHBcDate',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008630, 2, 22008630, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHCV_Date',       N'2026-03-25',   N'1', N'INV_FORM_HEPA', N'INV-LAB-031', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHCV_Date',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008631, 2, 22008631, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHDV',            N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-032', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHDV',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008632, 2, 22008632, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHDV_Date',       N'2026-03-26',   N'1', N'INV_FORM_HEPA', N'INV-LAB-033', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHDV_Date',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008633, 2, 22008633, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHEV',            N'negative',     N'1', N'INV_FORM_HEPA', N'INV-LAB-034', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHEV',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008634, 2, 22008634, N'D_INV_LAB_FINDING', N'LAB_TotalAntiHEV_Date',       N'2026-03-27',   N'1', N'INV_FORM_HEPA', N'INV-LAB-035', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TotalAntiHEV_Date',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008635, 2, 22008635, N'D_INV_LAB_FINDING', N'LAB_VerifiedTestDate',        N'2026-03-28',   N'1', N'INV_FORM_HEPA', N'INV-LAB-036', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'LAB_VerifiedTestDate',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_EPIDEMIOLOGY (25) ===================
(22008500, 22008636, 2, 22008636, N'D_INV_EPIDEMIOLOGY', N'EPI_ChildCareCase',          N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ChildCareCase',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008637, 2, 22008637, N'D_INV_EPIDEMIOLOGY', N'EPI_CNTRY_USUAL_RESID',      N'United States',N'1', N'INV_FORM_HEPA', N'INV-EPI-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_CNTRY_USUAL_RESID',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008638, 2, 22008638, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactBabysitter',      N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactBabysitter',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008639, 2, 22008639, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactChildcare',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactChildcare',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008640, 2, 22008640, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactHousehold',       N'Y',            N'1', N'INV_FORM_HEPA', N'INV-EPI-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactHousehold',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008641, 2, 22008641, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactOfCase',          N'Y',            N'1', N'INV_FORM_HEPA', N'INV-EPI-006', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactOfCase',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008642, 2, 22008642, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactOther',           N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-007', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactOther',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008643, 2, 22008643, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactOthSpecify',      N'Neighbor',     N'1', N'INV_FORM_HEPA', N'INV-EPI-008', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactOthSpecify',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008644, 2, 22008644, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactPlaymate',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-009', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactPlaymate',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008645, 2, 22008645, N'D_INV_EPIDEMIOLOGY', N'EPI_ContactSexPartner',      N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-010', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_ContactSexPartner',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008646, 2, 22008646, N'D_INV_EPIDEMIOLOGY', N'EPI_DaycareContact',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-011', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_DaycareContact',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008647, 2, 22008647, N'D_INV_EPIDEMIOLOGY', N'EPI_EpiLinked',              N'Y',            N'1', N'INV_FORM_HEPA', N'INV-EPI-012', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_EpiLinked',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008648, 2, 22008648, N'D_INV_EPIDEMIOLOGY', N'EPI_FemaleSexPartners',      N'0',            N'1', N'INV_FORM_HEPA', N'INV-EPI-013', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_FemaleSexPartners',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008649, 2, 22008649, N'D_INV_EPIDEMIOLOGY', N'EPI_FoodHandler',            N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-014', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_FoodHandler',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008650, 2, 22008650, N'D_INV_EPIDEMIOLOGY', N'EPI_InDayCare',              N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-015', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_InDayCare',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008651, 2, 22008651, N'D_INV_EPIDEMIOLOGY', N'EPI_IVDrugUse',              N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-016', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_IVDrugUse',              NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008652, 2, 22008652, N'D_INV_EPIDEMIOLOGY', N'EPI_MaleSexPartner',         N'1',            N'1', N'INV_FORM_HEPA', N'INV-EPI-017', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_MaleSexPartner',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008653, 2, 22008653, N'D_INV_EPIDEMIOLOGY', N'EPI_OutbreakFoodHndlr',      N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-018', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_OutbreakFoodHndlr',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008654, 2, 22008654, N'D_INV_EPIDEMIOLOGY', N'EPI_OutbreakFoodItem',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-019', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_OutbreakFoodItem',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008655, 2, 22008655, N'D_INV_EPIDEMIOLOGY', N'EPI_outbreakNonFoodHndlr',   N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-020', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_outbreakNonFoodHndlr',   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008656, 2, 22008656, N'D_INV_EPIDEMIOLOGY', N'EPI_OutbreakUnidentified',   N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-021', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_OutbreakUnidentified',   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008657, 2, 22008657, N'D_INV_EPIDEMIOLOGY', N'EPI_OutbreakWaterborne',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-022', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_OutbreakWaterborne',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008658, 2, 22008658, N'D_INV_EPIDEMIOLOGY', N'EPI_RecDrugUse',             N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-023', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_RecDrugUse',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008659, 2, 22008659, N'D_INV_EPIDEMIOLOGY', N'EPI_HEP_CONTACT_IND',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-EPI-024', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_HEP_CONTACT_IND',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008660, 2, 22008660, N'D_INV_EPIDEMIOLOGY', N'EPI_OutbreakAssoc',          N'Y',            N'1', N'INV_FORM_HEPA', N'INV-EPI-025', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'EPI_OutbreakAssoc',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_RISK_FACTOR (39) ===================
(22008500, 22008661, 2, 22008661, N'D_INV_RISK_FACTOR', N'RSK_BloodExpOther',           N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_BloodExpOther',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008662, 2, 22008662, N'D_INV_RISK_FACTOR', N'RSK_BloodTransfusion',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_BloodTransfusion',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008663, 2, 22008663, N'D_INV_RISK_FACTOR', N'RSK_BloodTransfusionDate',    N'2026-03-10',   N'1', N'INV_FORM_HEPA', N'INV-RSK-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_BloodTransfusionDate',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008664, 2, 22008664, N'D_INV_RISK_FACTOR', N'RSK_BloodWorkerCnctFreq',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_BloodWorkerCnctFreq',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008665, 2, 22008665, N'D_INV_RISK_FACTOR', N'RSK_BloodWorkerEver',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_BloodWorkerEver',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008666, 2, 22008666, N'D_INV_RISK_FACTOR', N'RSK_BloodWorkerOnset',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-006', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_BloodWorkerOnset',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008667, 2, 22008667, N'D_INV_RISK_FACTOR', N'RSK_ClottingPrior87',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-007', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_ClottingPrior87',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008668, 2, 22008668, N'D_INV_RISK_FACTOR', N'RSK_ContaminatedStick',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-008', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_ContaminatedStick',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008669, 2, 22008669, N'D_INV_RISK_FACTOR', N'RSK_DentalOralSx',            N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-009', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_DentalOralSx',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008670, 2, 22008670, N'D_INV_RISK_FACTOR', N'RSK_HEMODIALYSIS_BEFORE_ONSET',N'N',           N'1', N'INV_FORM_HEPA', N'INV-RSK-010', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_HEMODIALYSIS_BEFORE_ONSET',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008671, 2, 22008671, N'D_INV_RISK_FACTOR', N'RSK_HemodialysisLongTerm',    N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-011', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_HemodialysisLongTerm',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008672, 2, 22008672, N'D_INV_RISK_FACTOR', N'RSK_HospitalizedPrior',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-012', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_HospitalizedPrior',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008673, 2, 22008673, N'D_INV_RISK_FACTOR', N'RSK_IDU',                     N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-013', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IDU',                     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008674, 2, 22008674, N'D_INV_RISK_FACTOR', N'RSK_Incarcerated24Hrs',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-014', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_Incarcerated24Hrs',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008675, 2, 22008675, N'D_INV_RISK_FACTOR', N'RSK_Incarcerated6months',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-015', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_Incarcerated6months',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008676, 2, 22008676, N'D_INV_RISK_FACTOR', N'RSK_IncarceratedEver',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-016', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IncarceratedEver',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008677, 2, 22008677, N'D_INV_RISK_FACTOR', N'RSK_IncarceratedJail',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-017', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IncarceratedJail',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008678, 2, 22008678, N'D_INV_RISK_FACTOR', N'RSK_IncarcerationPrison',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-018', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IncarcerationPrison',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008679, 2, 22008679, N'D_INV_RISK_FACTOR', N'RSK_IncarcJuvenileFacilit',   N'0',            N'1', N'INV_FORM_HEPA', N'INV-RSK-019', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IncarcJuvenileFacilit',   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008680, 2, 22008680, N'D_INV_RISK_FACTOR', N'RSK_IncarcTimeMonths',        N'0',            N'1', N'INV_FORM_HEPA', N'INV-RSK-020', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IncarcTimeMonths',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008681, 2, 22008681, N'D_INV_RISK_FACTOR', N'RSK_IncarcYear6Mos',          N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-021', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IncarcYear6Mos',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008682, 2, 22008682, N'D_INV_RISK_FACTOR', N'RSK_IVInjectInfuseOutpt',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-022', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_IVInjectInfuseOutpt',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008683, 2, 22008683, N'D_INV_RISK_FACTOR', N'RSK_LongTermCareRes',         N'1',            N'1', N'INV_FORM_HEPA', N'INV-RSK-023', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_LongTermCareRes',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008684, 2, 22008684, N'D_INV_RISK_FACTOR', N'RSK_NumSexPrtners',           N'none',         N'1', N'INV_FORM_HEPA', N'INV-RSK-024', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_NumSexPrtners',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008685, 2, 22008685, N'D_INV_RISK_FACTOR', N'RSK_OtherBldExpSpec',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-025', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_OtherBldExpSpec',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008686, 2, 22008686, N'D_INV_RISK_FACTOR', N'RSK_Piercing',                N'none',         N'1', N'INV_FORM_HEPA', N'INV-RSK-026', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_Piercing',                NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008687, 2, 22008687, N'D_INV_RISK_FACTOR', N'RSK_PiercingOthLocSpec',      N'none',         N'1', N'INV_FORM_HEPA', N'INV-RSK-027', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_PiercingOthLocSpec',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008688, 2, 22008688, N'D_INV_RISK_FACTOR', N'RSK_PiercingRcvdFrom',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-028', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_PiercingRcvdFrom',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008689, 2, 22008689, N'D_INV_RISK_FACTOR', N'RSK_PSWrkrBldCnctFreq',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-029', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_PSWrkrBldCnctFreq',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008690, 2, 22008690, N'D_INV_RISK_FACTOR', N'RSK_PublicSafetyWorker',      N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-030', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_PublicSafetyWorker',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008691, 2, 22008691, N'D_INV_RISK_FACTOR', N'RSK_STDTxEver',               N'0',            N'1', N'INV_FORM_HEPA', N'INV-RSK-031', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_STDTxEver',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008692, 2, 22008692, N'D_INV_RISK_FACTOR', N'RSK_STDTxYr',                 N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-032', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_STDTxYr',                 NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008693, 2, 22008693, N'D_INV_RISK_FACTOR', N'RSK_SurgeryOther',            N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-033', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_SurgeryOther',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008694, 2, 22008694, N'D_INV_RISK_FACTOR', N'RSK_Tattoo',                  N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-034', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_Tattoo',                  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008695, 2, 22008695, N'D_INV_RISK_FACTOR', N'RSK_TattooLocation',          N'none',         N'1', N'INV_FORM_HEPA', N'INV-RSK-035', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_TattooLocation',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008696, 2, 22008696, N'D_INV_RISK_FACTOR', N'RSK_TattooLocOthSpec',        N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-036', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_TattooLocOthSpec',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008697, 2, 22008697, N'D_INV_RISK_FACTOR', N'RSK_TransfusionPrior92',      N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-037', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_TransfusionPrior92',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008698, 2, 22008698, N'D_INV_RISK_FACTOR', N'RSK_TransplantPrior92',       N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-038', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_TransplantPrior92',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008699, 2, 22008699, N'D_INV_RISK_FACTOR', N'RSK_HepContactEver',          N'N',            N'1', N'INV_FORM_HEPA', N'INV-RSK-039', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'RSK_HepContactEver',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_MEDICAL_HISTORY (9) ===================
(22008500, 22008700, 2, 22008700, N'D_INV_MEDICAL_HISTORY', N'MDH_DiabetesDxDate',      N'2026-01-01',   N'1', N'INV_FORM_HEPA', N'INV-MDH-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_DiabetesDxDate',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008701, 2, 22008701, N'D_INV_MEDICAL_HISTORY', N'MDH_Diabetes',            N'N',            N'1', N'INV_FORM_HEPA', N'INV-MDH-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_Diabetes',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008702, 2, 22008702, N'D_INV_MEDICAL_HISTORY', N'MDH_Jaundiced',           N'Y',            N'1', N'INV_FORM_HEPA', N'INV-MDH-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_Jaundiced',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008703, 2, 22008703, N'D_INV_MEDICAL_HISTORY', N'MDH_PrevAwareInfection',  N'N',            N'1', N'INV_FORM_HEPA', N'INV-MDH-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_PrevAwareInfection',  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008704, 2, 22008704, N'D_INV_MEDICAL_HISTORY', N'MDH_ProviderOfCare',      N'Primary Care', N'1', N'INV_FORM_HEPA', N'INV-MDH-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_ProviderOfCare',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008705, 2, 22008705, N'D_INV_MEDICAL_HISTORY', N'MDH_ReasonForTest',       N'Symptoms',     N'1', N'INV_FORM_HEPA', N'INV-MDH-006', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_ReasonForTest',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008706, 2, 22008706, N'D_INV_MEDICAL_HISTORY', N'MDH_ReasonForTestingOth', N'N/A',          N'1', N'INV_FORM_HEPA', N'INV-MDH-007', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_ReasonForTestingOth', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008707, 2, 22008707, N'D_INV_MEDICAL_HISTORY', N'MDH_Symptomatic',         N'Y',            N'1', N'INV_FORM_HEPA', N'INV-MDH-008', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_Symptomatic',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008708, 2, 22008708, N'D_INV_MEDICAL_HISTORY', N'MDH_DueDate',             N'2026-09-15',   N'1', N'INV_FORM_HEPA', N'INV-MDH-009', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MDH_DueDate',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_MOTHER (7) ===================
(22008500, 22008709, 2, 22008709, N'D_INV_MOTHER', N'MTH_MotherBornOutsideUS',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-MTH-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MotherBornOutsideUS',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008710, 2, 22008710, N'D_INV_MOTHER', N'MTH_MotherEthnicity',             N'Non-Hispanic', N'1', N'INV_FORM_HEPA', N'INV-MTH-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MotherEthnicity',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008711, 2, 22008711, N'D_INV_MOTHER', N'MTH_MotherHBsAgPosPrior',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-MTH-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MotherHBsAgPosPrior',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008712, 2, 22008712, N'D_INV_MOTHER', N'MTH_MotherPositiveAfter',         N'N',            N'1', N'INV_FORM_HEPA', N'INV-MTH-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MotherPositiveAfter',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008713, 2, 22008713, N'D_INV_MOTHER', N'MTH_MotherRace',                  N'White',        N'1', N'INV_FORM_HEPA', N'INV-MTH-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MotherRace',                  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008714, 2, 22008714, N'D_INV_MOTHER', N'MTH_MothersBirthCountry',         N'United States',N'1', N'INV_FORM_HEPA', N'INV-MTH-006', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MothersBirthCountry',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008715, 2, 22008715, N'D_INV_MOTHER', N'MTH_MotherPosTestDate',           N'2026-02-15',   N'1', N'INV_FORM_HEPA', N'INV-MTH-007', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'MTH_MotherPosTestDate',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_TRAVEL (5) ===================
(22008500, 22008716, 2, 22008716, N'D_INV_TRAVEL', N'TRV_HouseholdTravel',             N'N',            N'1', N'INV_FORM_HEPA', N'INV-TRV-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRV_HouseholdTravel',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008717, 2, 22008717, N'D_INV_TRAVEL', N'TRV_PatientTravel',               N'N',            N'1', N'INV_FORM_HEPA', N'INV-TRV-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRV_PatientTravel',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008718, 2, 22008718, N'D_INV_TRAVEL', N'TRV_PtTravelCountries',           N'none',         N'1', N'INV_FORM_HEPA', N'INV-TRV-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRV_PtTravelCountries',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008719, 2, 22008719, N'D_INV_TRAVEL', N'TRV_TravelCountryHouse',          N'none',         N'1', N'INV_FORM_HEPA', N'INV-TRV-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRV_TravelCountryHouse',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008720, 2, 22008720, N'D_INV_TRAVEL', N'TRV_VHF_TRAVEL_REASON',           N'Tourism',      N'1', N'INV_FORM_HEPA', N'INV-TRV-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'TRV_VHF_TRAVEL_REASON',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_ADMINISTRATIVE (3) ===================
(22008500, 22008721, 2, 22008721, N'D_INV_ADMINISTRATIVE', N'ADM_INNC_NOTIFICATION_DT',N'2026-04-04',   N'1', N'INV_FORM_HEPA', N'INV-ADM-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ADM_INNC_NOTIFICATION_DT',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008722, 2, 22008722, N'D_INV_ADMINISTRATIVE', N'ADM_FIRST_RPT_TO_PHD_DT', N'2026-03-24',   N'1', N'INV_FORM_HEPA', N'INV-ADM-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ADM_FIRST_RPT_TO_PHD_DT', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008723, 2, 22008723, N'D_INV_ADMINISTRATIVE', N'ADM_BINATIONAL_RPTNG_CRIT',N'BC-01',       N'1', N'INV_FORM_HEPA', N'INV-ADM-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'ADM_BINATIONAL_RPTNG_CRIT',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_CLINICAL (2) ===================
(22008500, 22008724, 2, 22008724, N'D_INV_CLINICAL', N'CLN_HepDInfection',             N'N',            N'1', N'INV_FORM_HEPA', N'INV-CLN-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CLN_HepDInfection',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008725, 2, 22008725, N'D_INV_CLINICAL', N'CLN_MedsforHep',                N'N',            N'1', N'INV_FORM_HEPA', N'INV-CLN-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'CLN_MedsforHep',                NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_PATIENT_OBS (1) ===================
(22008500, 22008726, 2, 22008726, N'D_INV_PATIENT_OBS', N'IPO_SEXUAL_PREF',             N'Hetero',       N'1', N'INV_FORM_HEPA', N'INV-IPO-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'IPO_SEXUAL_PREF',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
-- =================== D_INV_VACCINATION (8) ===================
(22008500, 22008727, 2, 22008727, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_GLOB_IND',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-VAC-001', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_GLOB_IND',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008728, 2, 22008728, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_GLOB_DT',      N'2025-01-15',   N'1', N'INV_FORM_HEPA', N'INV-VAC-002', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_GLOB_DT',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008729, 2, 22008729, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_REC',          N'N',            N'1', N'INV_FORM_HEPA', N'INV-VAC-003', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_REC',          NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008730, 2, 22008730, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_LAST_YR',      N'2025',         N'1', N'INV_FORM_HEPA', N'INV-VAC-004', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_LAST_YR',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008731, 2, 22008731, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_DOSES_GT',     N'N',            N'1', N'INV_FORM_HEPA', N'INV-VAC-005', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_DOSES_GT',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008732, 2, 22008732, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_DOSES_NBR',    N'0',            N'1', N'INV_FORM_HEPA', N'INV-VAC-006', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_DOSES_NBR',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008733, 2, 22008733, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_DOSE_RECV',    N'0',            N'1', N'INV_FORM_HEPA', N'INV-VAC-007', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_DOSE_RECV',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
(22008500, 22008734, 2, 22008734, N'D_INV_VACCINATION', N'VAC_HEP_A_VACC_FOUR_OR_MORE', N'False',        N'1', N'INV_FORM_HEPA', N'INV-VAC-008', N'NBS_Case_Answer.answer_txt', NULL, '2026-04-01T00:00:00', N'ACTIVE', N'VAC_HEP_A_VACC_FOUR_OR_MORE', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active');
END;

GO

-- =====================================================================
-- Tail-EXECs: flow the Investigation row, run pagebuilder/f_page_case,
-- finally hepatitis datamart. Wrap each in TRY/CATCH so chain failures
-- don't abort downstream fixtures in merge_and_verify.sh.
-- =====================================================================

USE [RDB_MODERN];
GO

BEGIN TRY
    EXEC dbo.sp_nrt_investigation_postprocessing
        @id_list = N'22008500',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_nrt_investigation_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- F_PAGE_CASE: required for sp_hepatitis_datamart_postprocessing to
-- discover the investigation→D_INV_* linkage via F_PAGE_CASE rows.
BEGIN TRY
    EXEC dbo.sp_f_page_case_postprocessing
        @phc_ids = N'22008500',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_f_page_case_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- HEPATITIS_DATAMART: pivots D_INV_* into HEPATITIS_DATAMART for
-- condition_cd IN ('10110', ...). Param @phc_id (not @phc_id_list,
-- not @phc_uids) — verified by grep on the SP signature line 10.
BEGIN TRY
    EXEC dbo.sp_hepatitis_datamart_postprocessing
        @phc_id = N'22008500',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_hepatitis_datamart_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- HEPATITIS_LDF (separate LDF dim): param @phc_uids (verified by grep
-- on 320-sp_ldf_hepatitis_datamart_postprocessing-001.sql line 10).
BEGIN TRY
    EXEC dbo.sp_ldf_hepatitis_datamart_postprocessing
        @phc_uids = N'22008500',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'sp_ldf_hepatitis_datamart_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO
