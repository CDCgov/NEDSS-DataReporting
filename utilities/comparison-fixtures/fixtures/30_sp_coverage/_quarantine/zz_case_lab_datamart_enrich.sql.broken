-- =====================================================================
-- Tier 3 — CASE_LAB_DATAMART column-coverage enrichment (agent-K)
-- =====================================================================
-- Authored 2026-05-24 by Agent K (parallel enrichment, round 2 top-up).
--
-- Goal: lift dbo.CASE_LAB_DATAMART populated-column count from 9/35
-- toward 30+/35 by enriching the upstream tables the SP reads.
--
-- WHY 9/35 BEFORE
--   dbo.CASE_LAB_DATAMART has 20 rows but only 9 cols populated. All 20
--   rows have the SAME cols NULL (per per-col COUNT scan): demographics,
--   provider, reporting source, lab info, condition, event-metric.
--
--   Diagnosis (live):
--     - CASE_COUNT for the 23 existing PHCs joins ok (PATIENT_KEY=3 has
--       real D_PATIENT row), but PHYSICIAN_KEY=1 and RPT_SRC_ORG_KEY=1
--       are the placeholder "unknown" rows in D_PROVIDER / D_ORGANIZATION
--       (NULL names), so PHYSICIAN_NAME / PHYSICIAN_PHONE /
--       REPORTING_SOURCE collapse to NULL after the SP's LEFT JOIN.
--     - dbo.lab100 is EMPTY (0 rows), so LABORATORY_INFORMATION and
--       EARLIEST_SPECIMEN_COLLECT_DATE collapse to NULL for every row.
--     - The existing case_lab_datamart rows were populated at a time
--       BEFORE D_PATIENT.PATIENT_KEY=3 existed; the SP DELETE-then-
--       INSERTs by INVESTIGATION_KEY, so once we re-run after this
--       enrichment, the demographics WILL populate from D_PATIENT.
--     - CONDITION rows for all referenced CONDITION_KEYs already have
--       CONDITION_CD, CONDITION_SHORT_NM, PROGRAM_AREA_DESC populated,
--       so DISEASE / DISEASE_CD / PROGRAM_AREA_DESCRIPTION will lift.
--     - EVENT_METRIC_INC rows exist for ALL 23 existing PHCs (matched
--       on event_uid = inv.case_uid), so PHC_ADD_TIME / PHC_LAST_CHG_TIME
--       lift automatically once SP re-runs.
--
-- STRATEGY (a + b): enrich existing investigations.
--   1. UPDATE D_PROVIDER key=2 to add a phone (so PHYSICIAN_PHONE lifts).
--   2. UPDATE CASE_COUNT for the 23 existing PHCs to set PHYSICIAN_KEY=2
--      and RPT_SRC_ORG_KEY=2 (real names with key=2).
--   3. INSERT lab100 rows for the 3 foundation/Tier-1 lab observations
--      (OBS20000120GA01, OBS20070010GA01, OBS20070011GA01). These feed
--      sample2/3/4/5 -> LABORATORY_INFORMATION and feed
--      EARLIEST_SPECIMEN_COLLECT_DATE.
--   4. INSERT LAB_TEST_RESULT rows linking the existing LAB_TEST_KEYs
--      (101 -> lab100 OBS20000120, 102/103 -> OBS20070010/0011) to MORE
--      investigation_keys so more datamart rows acquire lab info.
--
-- COL LIFT TARGET
--   Current 9/35 -> target ~30/35 (+21 cols). Will not populate at most:
--     - LABORATORY_INFORMATION on rows w/o lab linkage (we add some via
--       LAB_TEST_RESULT inserts but not exhaustive — counts at TABLE
--       level, so 1 row populated is enough).
--     - EARLIEST_SPECIMEN_COLLECT_DATE — same as above.
--
-- UID ALLOCATION (within reserved block 22017000-22017999)
--   22017101 lab100 LAB_RPT_LOCAL_ID = OBS20000120GA01 (already exists)
--   22017102 lab100 LAB_RPT_LOCAL_ID = OBS20070010GA01 (already exists)
--   22017103 lab100 LAB_RPT_LOCAL_ID = OBS20070011GA01 (already exists)
--   22017200-22017210 LAB_TEST_RESULT supplemental rows
--
-- DOES NOT TOUCH
--   - dbo.case_lab_datamart directly (SP DELETE-then-INSERTs by inv key).
--   - Tier-0/1/2 foundation rows of D_PATIENT / D_PROVIDER (only adds
--     phone to PROVIDER_KEY=2 if it was NULL; idempotent guard).
--   - INVESTIGATION rows (already populated with dates/comments).
--
-- VERIFICATION (tail-EXEC; sees only some PHCs since fixture-local)
--   EXEC sp_case_lab_datamart_postprocessing
--        @phc_id = N'20000100,20050010,22001000,...', @debug=0
--
-- ORCH_TODO
--   None. PHCs 20000100,20050010,22000010..22010000 are already in
--   merge_and_verify.sh PHC_UIDS. The orchestrator's run will pick up
--   the SP re-run and lift cols on ALL 20 existing rows.
-- =====================================================================

USE [RDB_MODERN];
GO

SET XACT_ABORT ON;
SET NOCOUNT ON;

BEGIN TRY

-- =====================================================================
-- 1. D_PROVIDER PROVIDER_KEY=2 — populate phone so PHYSICIAN_PHONE lifts.
--    Idempotent: only updates if currently NULL.
-- =====================================================================
UPDATE dbo.D_PROVIDER
SET PROVIDER_PHONE_WORK = '404-555-0200'
WHERE PROVIDER_KEY = 2 AND (PROVIDER_PHONE_WORK IS NULL OR PROVIDER_PHONE_WORK = '');

-- =====================================================================
-- 2. CASE_COUNT — set PHYSICIAN_KEY=2 (John Xerogeanes) and
--    RPT_SRC_ORG_KEY=2 (Piedmont Hospital) for all 23 existing PHCs.
--    Existing rows have PHYSICIAN_KEY=1 / RPT_SRC_ORG_KEY=1 (unknown).
--    Idempotent: only updates rows still set to the placeholder 1.
-- =====================================================================
UPDATE cc
SET cc.PHYSICIAN_KEY = 2,
    cc.RPT_SRC_ORG_KEY = 2
FROM dbo.CASE_COUNT cc
JOIN dbo.INVESTIGATION i ON cc.INVESTIGATION_KEY = i.INVESTIGATION_KEY
WHERE i.CASE_UID IN (
    '20000100','20050010','22000010','22000020','22000030','22000040',
    '22000050','22000060','22000070','22000080','22000090','22000100',
    '22000200','22001000','22002000','22003000','22004000','22005000',
    '22007000','22008000','22008500','22009000','22010000'
)
  AND (cc.PHYSICIAN_KEY = 1 OR cc.RPT_SRC_ORG_KEY = 1);

-- =====================================================================
-- 3. lab100 — author rows matching the 3 existing LAB_RPT_LOCAL_IDs
--    referenced via LAB_TEST. SP joins lab100 by LAB_RPT_LOCAL_ID, not
--    a numeric key, so the fields below are the *only* lab data the SP
--    sees for building LABORATORY_INFORMATION + EARLIEST_SPECIMEN_*.
--
--    NOTE: lab100 has no primary key declared in the live schema; we
--    guard via IF NOT EXISTS on LAB_RPT_LOCAL_ID to keep idempotency.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.lab100 WHERE LAB_RPT_LOCAL_ID = 'OBS20000120GA01')
BEGIN
    INSERT INTO dbo.lab100
        (LAB_RPT_LOCAL_ID, RECORD_STATUS_CD, RESULTED_LAB_TEST_CD,
         RESULTED_LAB_TEST_CD_DESC, RESULTEDTEST_VAL_CD,
         RESULTEDTEST_VAL_CD_DESC, NUMERIC_RESULT_WITHUNITS,
         LAB_RESULT_TXT_VAL, LAB_RESULT_COMMENTS,
         LAB_RPT_RECEIVED_BY_PH_DT, SPECIMEN_COLLECTION_DT,
         LAB_TEST_DT, LAB_RPT_CREATED_DT, ELR_IND,
         JURISDICTION_NM, PATIENT_KEY, CONDITION_CD, CONDITION_SHORT_NM,
         PROGRAM_AREA_CD, PROGRAM_AREA_DESC,
         RESULTED_LAB_TEST_KEY, EVENT_DATE)
    VALUES
        ('OBS20000120GA01', 'ACTIVE', 'LAB100',
         'Foundation lab test (RNA detected)', '10828004',
         'Positive', '4.2 log copies/mL',
         'Detected', 'Foundation lab confirms positive result.',
         '2026-04-01T00:00:00', '2026-03-30T00:00:00',
         '2026-03-31T00:00:00', '2026-04-01T00:00:00', 'Y',
         'Fulton County', 3, '10110', 'Hepatitis A, acute',
         'HEP', 'HEP', 101, '2026-03-30T00:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.lab100 WHERE LAB_RPT_LOCAL_ID = 'OBS20070010GA01')
BEGIN
    INSERT INTO dbo.lab100
        (LAB_RPT_LOCAL_ID, RECORD_STATUS_CD, RESULTED_LAB_TEST_CD,
         RESULTED_LAB_TEST_CD_DESC, RESULTEDTEST_VAL_CD,
         RESULTEDTEST_VAL_CD_DESC, NUMERIC_RESULT_WITHUNITS,
         LAB_RESULT_TXT_VAL, LAB_RESULT_COMMENTS,
         LAB_RPT_RECEIVED_BY_PH_DT, SPECIMEN_COLLECTION_DT,
         LAB_TEST_DT, LAB_RPT_CREATED_DT, ELR_IND,
         JURISDICTION_NM, PATIENT_KEY, CONDITION_CD, CONDITION_SHORT_NM,
         PROGRAM_AREA_CD, PROGRAM_AREA_DESC,
         RESULTED_LAB_TEST_KEY, EVENT_DATE)
    VALUES
        ('OBS20070010GA01', 'ACTIVE', 'TPPA',
         'Treponema pallidum particle agglutination', 'POS',
         'Reactive', NULL,
         'Reactive 1:512', 'Confirmatory treponemal test.',
         '2026-04-04T00:00:00', '2026-04-02T00:00:00',
         '2026-04-03T00:00:00', '2026-04-04T00:00:00', 'Y',
         'Fulton County', 3, '10311', 'Syphilis, primary',
         'STD', 'STD', 102, '2026-04-02T00:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.lab100 WHERE LAB_RPT_LOCAL_ID = 'OBS20070011GA01')
BEGIN
    INSERT INTO dbo.lab100
        (LAB_RPT_LOCAL_ID, RECORD_STATUS_CD, RESULTED_LAB_TEST_CD,
         RESULTED_LAB_TEST_CD_DESC, RESULTEDTEST_VAL_CD,
         RESULTEDTEST_VAL_CD_DESC, NUMERIC_RESULT_WITHUNITS,
         LAB_RESULT_TXT_VAL, LAB_RESULT_COMMENTS,
         LAB_RPT_RECEIVED_BY_PH_DT, SPECIMEN_COLLECTION_DT,
         LAB_TEST_DT, LAB_RPT_CREATED_DT, ELR_IND,
         JURISDICTION_NM, PATIENT_KEY, CONDITION_CD, CONDITION_SHORT_NM,
         PROGRAM_AREA_CD, PROGRAM_AREA_DESC,
         RESULTED_LAB_TEST_KEY, EVENT_DATE)
    VALUES
        ('OBS20070011GA01', 'ACTIVE', 'RPR',
         'Rapid plasma reagin', 'POS',
         'Reactive', '1:32 titer',
         'Reactive', 'Non-treponemal screen.',
         '2026-04-04T00:00:00', '2026-04-02T00:00:00',
         '2026-04-03T00:00:00', '2026-04-04T00:00:00', 'Y',
         'Fulton County', 3, '10311', 'Syphilis, primary',
         'STD', 'STD', 103, '2026-04-02T00:00:00');
END;

-- =====================================================================
-- 4. LAB_TEST_RESULT — link existing labs (LAB_TEST_KEY=101/102/103) to
--    MORE INVESTIGATION_KEYs so more case_lab_datamart rows receive
--    LABORATORY_INFORMATION + EARLIEST_SPECIMEN_COLLECT_DATE.
--
--    Existing LAB_TEST_RESULTs are 101->inv 3, 102->inv 4, 103->inv 4.
--    We add rows for inv keys belonging to PHCs 22001000..22010000.
--    Idempotent via SELECT/EXCEPT.
-- =====================================================================
-- pull investigation_keys for additional PHCs (TB / GCD / etc.)
;WITH targets AS (
    SELECT INVESTIGATION_KEY
    FROM dbo.INVESTIGATION
    WHERE CASE_UID IN (
        '22001000','22002000','22005000','22007000','22008000',
        '22000010','22000020','22000030','22000040','22000050',
        '22000060','22000070'
    )
)
INSERT INTO dbo.LAB_TEST_RESULT (LAB_TEST_KEY, INVESTIGATION_KEY, RECORD_STATUS_CD)
SELECT 101, t.INVESTIGATION_KEY, 'ACTIVE'
FROM targets t
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.LAB_TEST_RESULT ltr
    WHERE ltr.LAB_TEST_KEY = 101 AND ltr.INVESTIGATION_KEY = t.INVESTIGATION_KEY
);

-- =====================================================================
-- TAIL-EXEC — verification run.
-- Pass the full PHC list so we re-DELETE/INSERT all 20 rows.
-- =====================================================================
EXEC dbo.sp_case_lab_datamart_postprocessing
     @phc_id = N'20000100,20050010,22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100,22000200,22001000,22002000,22003000,22004000,22005000,22007000,22008000,22008500,22009000,22010000',
     @debug = 0;

PRINT 'zz_case_lab_datamart_enrich.sql: completed';

END TRY
BEGIN CATCH
    PRINT 'ERROR in zz_case_lab_datamart_enrich.sql: ' + ERROR_MESSAGE() + ' (line ' + CAST(ERROR_LINE() AS varchar) + ')';
    THROW;
END CATCH;
GO
