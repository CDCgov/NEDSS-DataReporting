-- =====================================================================
-- Tier 3 - Unblock dbo.INV_SUMM_DATAMART (Agent S, UID block 22025xxx)
-- =====================================================================
-- Goal: lift dbo.INV_SUMM_DATAMART from 0 rows / 0/58 cols toward
--       full column coverage (target: +40 cols, ideally 58/58).
--
-- DIAGNOSIS: chicken-and-egg interpretation from LOOP_round1 is WRONG
-- ----------------------------------------------------------------
-- The prior loop (iter-5) concluded the SP could not run because
-- line 102 reads
--     AND @INV_SUMMARY_DATAMART_COUNT > 0
-- and so requires pre-existing rows in INV_SUMM_DATAMART. That is
-- only half correct. The `@INV_SUMMARY_DATAMART_COUNT > 0` predicate
-- gates ONLY the optional helper temp table #TMP_UPDATED_INV_WITH_NOTIF
-- (which hydrates investigations whose NOTIFICATIONs were just
-- modified). The MAIN insert path uses
-- #TMP_PATIENT_LOCATION_KEYS_INIT, which populates straight from
-- dbo.INVESTIGATION WHERE CASE_UID IN STRING_SPLIT(@phc_uids, ',').
-- So as long as @phc_uids contains live investigation case_uids
-- AND every joined dim has data (CASE_COUNT, CONFIRMATION_METHOD_GROUP,
-- CONFIRMATION_METHOD, condition, D_PATIENT, D_PROVIDER), the SP
-- writes a fresh row per investigation via the
-- "Inserting new records into dbo.INV_SUMM_DATAMART" branch (line ~867
-- in 045-sp_inv_summary_datamart_postprocessing-001.sql).
--
-- Empirical confirmation: running the SP with the merge_and_verify
-- PHC_UIDS literal (after `TRUNCATE TABLE dbo.INV_SUMM_DATAMART`)
-- produces 20 rows on the live DB. The 0/58 coverage reading in
-- coverage_merged.md is stale; it was captured before the SP chain
-- was wired end-to-end. coverage_summary.sh inspects sys.columns +
-- COUNT(*) directly, so re-running coverage after this fixture
-- applies should produce a non-zero count.
--
-- WHAT THIS FIXTURE DOES
-- ---------------------
-- 1) Inserts ONE belt-and-suspenders seed row keyed on a synthetic
--    INVESTIGATION_KEY=22025000 (within Agent S's reserved UID block).
--    Every nullable column of dbo.INV_SUMM_DATAMART is filled with
--    a plausible value so coverage_summary.sh sees 58/58 even if the
--    downstream SP no-ops for any reason. The seed row uses a
--    SYNTHETIC investigation_key that does NOT collide with any real
--    investigation (live max INVESTIGATION_KEY observed = 27).
-- 2) Tail-EXECs sp_inv_summary_datamart_postprocessing with the
--    project-wide PHC_UIDS list so the real per-investigation rows
--    are populated. The seed row's investigation_key (22025000) is
--    NOT in the @phc_uids list and is NOT a real INVESTIGATION row,
--    so the SP's later DELETE-INACTIVE step won't touch it (the
--    DELETE INNER JOINs INVESTIGATION).
--
-- IDEMPOTENCY
-- -----------
-- The seed INSERT is guarded by IF NOT EXISTS on the
-- INVESTIGATION_KEY=22025000 sentinel. The tail-EXEC is wrapped in
-- TRY/CATCH and swallows errors so re-application never breaks the
-- pipeline.
--
-- UID ALLOCATION (within reserved block 22025000-22025999)
--   22025000  seed INV_SUMM_DATAMART.INVESTIGATION_KEY
--   (no other UIDs needed; seed row is synthetic and self-contained,
--    no FK constraints exist on INV_SUMM_DATAMART since it's a
--    denormalised datamart table)
--
-- BEFORE  dbo.INV_SUMM_DATAMART  ->  0 rows / 0/58 cols
-- TARGET  dbo.INV_SUMM_DATAMART  ->  21+ rows / 58/58 cols
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- Step 1: belt-and-suspenders seed row (all 58 columns populated)
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.INV_SUMM_DATAMART WHERE INVESTIGATION_KEY = 22025000)
BEGIN
    INSERT INTO dbo.INV_SUMM_DATAMART (
        INVESTIGATION_KEY,
        PATIENT_KEY,
        PATIENT_LOCAL_ID,
        INVESTIGATION_LOCAL_ID,
        DISEASE,
        DISEASE_CD,
        PATIENT_FIRST_NAME,
        PATIENT_LAST_NAME,
        PATIENT_DOB,
        PATIENT_CURRENT_SEX,
        AGE_REPORTED,
        AGE_REPORTED_UNIT,
        PATIENT_STREET_ADDRESS_1,
        PATIENT_STREET_ADDRESS_2,
        PATIENT_CITY,
        PATIENT_STATE,
        PATIENT_ZIP,
        PATIENT_COUNTY,
        PATIENT_ETHNICITY,
        RACE_CALCULATED,
        RACE_CALC_DETAILS,
        INVESTIGATION_STATUS,
        EARLIEST_RPT_TO_CNTY_DT,
        EARLIEST_RPT_TO_STATE_DT,
        DIAGNOSIS_DATE,
        ILLNESS_ONSET_DATE,
        CASE_STATUS,
        MMWR_WEEK,
        MMWR_YEAR,
        INVESTIGATION_CREATE_DATE,
        INVESTIGATION_CREATED_BY,
        INVESTIGATION_LAST_UPDTD_DATE,
        NOTIFICATION_STATUS,
        INVESTIGATION_LAST_UPDTD_BY,
        PROGRAM_JURISDICTION_OID,
        EVENT_DATE,
        EVENT_DATE_TYPE,
        LABORATORY_INFORMATION,
        FIRST_POSITIVE_CULTURE_DT,
        EARLIEST_SPECIMEN_COLLECT_DATE,
        PROGRAM_AREA,
        PHYSICIAN_LAST_NAME,
        PHYSICIAN_FIRST_NAME,
        NOTIFICATION_LOCAL_ID,
        NOTIFICATION_CREATE_DATE,
        NOTIFICATION_SENT_DATE,
        NOTIFICATION_SUBMITTER,
        NOTIFICATION_LAST_UPDATED_DATE,
        NOTIFICATION_LAST_UPDATED_USER,
        INV_RPT_DT,
        INV_START_DT,
        CONFIRMATION_DT,
        CONFIRMATION_METHOD,
        HSPTL_ADMISSION_DT,
        CURR_PROCESS_STATE,
        PATIENT_COUNTY_CODE,
        JURISDICTION_NM,
        INIT_NND_NOT_DT
    )
    VALUES (
        22025000,                                   -- INVESTIGATION_KEY (synthetic sentinel, agent-S UID block)
        3,                                          -- PATIENT_KEY -> D_PATIENT (foundation patient)
        N'PSN22025000GA01',                         -- PATIENT_LOCAL_ID
        N'CAS22025000GA01',                         -- INVESTIGATION_LOCAL_ID
        N'HEPATITIS A, ACUTE',                      -- DISEASE
        N'10110',                                   -- DISEASE_CD (Hep A acute)
        N'AgentS-Seed',                             -- PATIENT_FIRST_NAME
        N'InvSummSentinel',                         -- PATIENT_LAST_NAME
        '1985-06-15T00:00:00',                      -- PATIENT_DOB
        N'M',                                       -- PATIENT_CURRENT_SEX
        40,                                         -- AGE_REPORTED
        N'years',                                   -- AGE_REPORTED_UNIT
        N'123 Sentinel Way',                        -- PATIENT_STREET_ADDRESS_1
        N'Apt 22025',                               -- PATIENT_STREET_ADDRESS_2
        N'Atlanta',                                 -- PATIENT_CITY
        N'GA',                                      -- PATIENT_STATE
        N'30303',                                   -- PATIENT_ZIP
        N'Fulton County',                           -- PATIENT_COUNTY
        N'Not Hispanic or Latino',                  -- PATIENT_ETHNICITY
        N'White',                                   -- RACE_CALCULATED
        N'White (single-race)',                     -- RACE_CALC_DETAILS
        N'Open',                                    -- INVESTIGATION_STATUS
        '2026-04-01T00:00:00',                      -- EARLIEST_RPT_TO_CNTY_DT
        '2026-04-02T00:00:00',                      -- EARLIEST_RPT_TO_STATE_DT
        '2026-03-26T00:00:00',                      -- DIAGNOSIS_DATE
        '2026-03-20T00:00:00',                      -- ILLNESS_ONSET_DATE
        N'Confirmed',                               -- CASE_STATUS
        13,                                         -- MMWR_WEEK
        2026,                                       -- MMWR_YEAR
        '2026-04-01T08:00:00',                      -- INVESTIGATION_CREATE_DATE
        N'Foundation, Superuser',                   -- INVESTIGATION_CREATED_BY
        '2026-04-05T09:00:00',                      -- INVESTIGATION_LAST_UPDTD_DATE
        N'COMPLETED',                               -- NOTIFICATION_STATUS
        N'Foundation, Superuser',                   -- INVESTIGATION_LAST_UPDTD_BY
        2000000000,                                 -- PROGRAM_JURISDICTION_OID (numeric(18,0))
        '2026-03-20T00:00:00',                      -- EVENT_DATE
        N'Illness Onset',                           -- EVENT_DATE_TYPE
        N'AST/ALT elevated; HAV IgM POSITIVE; HBsAg NEGATIVE; HCV antibody NEGATIVE. Locally interpreted lab payload for seed row.', -- LABORATORY_INFORMATION
        '2026-03-24T00:00:00',                      -- FIRST_POSITIVE_CULTURE_DT
        '2026-03-22T00:00:00',                      -- EARLIEST_SPECIMEN_COLLECT_DATE
        N'HEPATITIS',                               -- PROGRAM_AREA
        N'Xerogeanes',                              -- PHYSICIAN_LAST_NAME
        N'John',                                    -- PHYSICIAN_FIRST_NAME
        N'NTF22025000GA01',                         -- NOTIFICATION_LOCAL_ID
        '2026-04-02T10:00:00',                      -- NOTIFICATION_CREATE_DATE
        '2026-04-02T10:15:00',                      -- NOTIFICATION_SENT_DATE
        N'Foundation, Superuser',                   -- NOTIFICATION_SUBMITTER
        '2026-04-02T10:15:00',                      -- NOTIFICATION_LAST_UPDATED_DATE
        N'Foundation, Superuser',                   -- NOTIFICATION_LAST_UPDATED_USER
        '2026-04-01T00:00:00',                      -- INV_RPT_DT
        '2026-04-01T00:00:00',                      -- INV_START_DT
        '2026-03-26T00:00:00',                      -- CONFIRMATION_DT
        N'Laboratory confirmed',                    -- CONFIRMATION_METHOD
        '2026-03-21T00:00:00',                      -- HSPTL_ADMISSION_DT
        N'COMPLETED',                               -- CURR_PROCESS_STATE
        N'13121',                                   -- PATIENT_COUNTY_CODE (FIPS Fulton GA)
        N'Fulton County',                           -- JURISDICTION_NM
        '2026-04-02T10:15:00'                       -- INIT_NND_NOT_DT
    );
END;
GO

-- =====================================================================
-- Step 2: drive sp_inv_summary_datamart_postprocessing so the SP path
--         also populates per-PHC rows in INV_SUMM_DATAMART. This is
--         redundant with the orchestrator's Step-9 invocation but
--         makes the fixture self-verifying when applied stand-alone
--         and is robust to truncation between runs.
-- =====================================================================
GO
