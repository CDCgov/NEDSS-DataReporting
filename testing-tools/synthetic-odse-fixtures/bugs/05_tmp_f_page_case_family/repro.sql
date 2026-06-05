/*
================================================================================
RTR Bug #5 — Self-contained reproduction
sp_hepatitis_datamart_postprocessing — TWO bugs surfaced during investigation
================================================================================

ORIGINAL HYPOTHESIS (per coverage_tier_3.md): the SP's #TMP_F_PAGE_CASE
projection returns 0 rows from inside the SP even when the equivalent
manual query returns rows; suspected snapshot-isolation / transaction-scope
quirk shared across the entire condition-datamart SP family.

ACTUAL FINDINGS:

  Bug 5a (LOGGING bug, NOT a data bug):
    The job_flow_log row_count for step 3 ("Generating  #TMP_F_PAGE_CASE")
    is ALWAYS 0 in production runs. The temp table itself is correctly
    populated. The bug is at SP line 108-111:

        SELECT ... INTO #TMP_F_PAGE_CASE FROM ...;
        IF @debug ='true' SELECT * FROM #TMP_F_PAGE_CASE;  -- line 108
        SELECT @ROWCOUNT_NO = @@ROWCOUNT;                  -- line 111

    When @debug='false' (the production default), the IF statement
    evaluates the predicate but executes no SELECT. SQL Server's
    @@ROWCOUNT is set to 0 by the IF false-branch, so the captured
    @ROWCOUNT_NO is 0 — even though the SELECT INTO populated rows.

    Verified by running the SP twice — once with @debug=0, once with
    @debug=1 — the LATER step row_counts (steps 4-18) are identical
    (=1 row each), proving #TMP_F_PAGE_CASE was populated either way.

  Bug 5b (FIXTURE bug, surfaced by 5a):
    The reason HEPATITIS_DATAMART stays empty is NOT step 3. It is
    step 25 (TMP_HEPATITIS_CASE_BASE) → followed by line 2148-2150:

        DELETE FROM #TMP_HEPATITIS_CASE_BASE WHERE PATIENT_UID IS NULL;

    The single row in #TMP_HEPATITIS_CASE_BASE has PATIENT_UID=NULL
    because:
      a) nrt_investigation.patient_id is NULL for the foundation
         Investigation (CASE_UID=20000100). NRT-side data was never
         populated with a patient_id.
      b) sp_f_page_case_postprocessing line 142
         COALESCE(PATIENT.PATIENT_KEY, 1) — falls back to sentinel
         PATIENT_KEY=1 when D_PATIENT.PATIENT_UID join misses.
      c) D_PATIENT.PATIENT_KEY=1 is the "unknown" sentinel row with
         PATIENT_UID=NULL by design.
      d) #TMP_D_Patient (step 14) JOINs F_PAGE_CASE.PATIENT_KEY=1 ->
         D_PATIENT.PATIENT_KEY=1 -> PATIENT_UID=NULL.
      e) #TMP_HEPATITIS_CASE_BASE inherits PATIENT_UID=NULL.
      f) DELETE removes the row -> 0 rows inserted into HEPATITIS_DATAMART.

    The fix is FIXTURE-side: populate nrt_investigation.patient_id
    with a real patient_uid that maps to a non-sentinel D_PATIENT row.

OTHER FAMILY SPs (revised scope):
    The original bug description listed 10 SPs as sharing the
    #TMP_F_PAGE_CASE pattern. Verified via grep — ONLY
    013-sp_hepatitis_datamart_postprocessing actually uses
    #TMP_F_PAGE_CASE. The other 9 SPs (tb, var, covid, pertussis,
    measles, rubella, std_hiv, bmird_strep_pneumo, crs) use entirely
    different temp-table constructions (#S_PHC_LIST, #S_INVESTIGATION_LIST,
    #PATIENT, etc.) and DO NOT exhibit the @@ROWCOUNT logging bug at
    that step. Their 0-row symptoms are unrelated and need their own
    investigations.

How to run (sqlcmd on localhost:3433):
    export SQLCMDPASSWORD=PizzaIsGood33!
    sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql

Inputs:
    @phc_id = '20000100' (foundation Investigation CASE_UID, condition Hep A)

Pre-condition: F_PAGE_CASE may or may not be populated for the foundation.
This script regenerates it via sp_f_page_case_postprocessing.
================================================================================
*/

SET NOCOUNT ON;
USE RDB_MODERN;
GO

PRINT '================================================================================';
PRINT 'STEP 0: Environment / isolation state';
PRINT '================================================================================';

SELECT
    name,
    snapshot_isolation_state,
    snapshot_isolation_state_desc,
    is_read_committed_snapshot_on
FROM sys.databases
WHERE name = 'RDB_MODERN';
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 1: Ensure F_PAGE_CASE is populated for foundation Investigation';
PRINT '         (regenerate so this script is idempotent)';
PRINT '================================================================================';

EXEC dbo.sp_f_page_case_postprocessing @phc_ids = N'20000100', @debug = 0;
GO

PRINT '';
PRINT 'F_PAGE_CASE rows after sp_f_page_case_postprocessing:';

SELECT INVESTIGATION_KEY, CONDITION_KEY, PATIENT_KEY
FROM dbo.F_PAGE_CASE WITH(NOLOCK);
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 2: Manual TMP_F_PAGE_CASE projection (SAME query the SP runs at line 95-103)';
PRINT '         Expected: returns 1 row (INVESTIGATION_KEY=3, CONDITION_KEY=6, PATIENT_KEY=1)';
PRINT '================================================================================';

DECLARE @phc_id_manual nvarchar(max) = N'20000100';

IF OBJECT_ID('tempdb..#TMP_CONDITION_MANUAL', 'U') IS NOT NULL DROP TABLE #TMP_CONDITION_MANUAL;
IF OBJECT_ID('tempdb..#TMP_F_PAGE_CASE_MANUAL', 'U') IS NOT NULL DROP TABLE #TMP_F_PAGE_CASE_MANUAL;

SELECT CONDITION_CD, CONDITION_DESC, DISEASE_GRP_DESC, CONDITION_KEY
INTO #TMP_CONDITION_MANUAL
FROM dbo.condition WITH(NOLOCK)
WHERE CONDITION_CD IN ('10110','10104','10100','10106','10101','10102','10103','10105','10481','50248','999999');

SELECT F_PAGE_CASE.INVESTIGATION_KEY, T.CONDITION_KEY, F_PAGE_CASE.PATIENT_KEY
INTO #TMP_F_PAGE_CASE_MANUAL
FROM dbo.F_PAGE_CASE WITH(NOLOCK)
    INNER JOIN #TMP_CONDITION_MANUAL T WITH(NOLOCK) ON F_PAGE_CASE.CONDITION_KEY = T.CONDITION_KEY
    INNER JOIN dbo.D_PATIENT WITH(NOLOCK) ON F_PAGE_CASE.PATIENT_KEY = D_PATIENT.PATIENT_KEY
    INNER JOIN dbo.INVESTIGATION WITH(NOLOCK) ON INVESTIGATION.INVESTIGATION_KEY = F_PAGE_CASE.INVESTIGATION_KEY
WHERE INVESTIGATION.CASE_UID IN (SELECT value FROM STRING_SPLIT(@phc_id_manual, ','))
  AND INVESTIGATION.RECORD_STATUS_CD = 'ACTIVE';

DECLARE @manual_rc int = @@ROWCOUNT;

SELECT 'manual_query' AS source, @manual_rc AS row_count;
SELECT 'manual_rows' AS source, * FROM #TMP_F_PAGE_CASE_MANUAL;
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 3: Demonstrate the @@ROWCOUNT-after-IF bug in isolation';
PRINT '         This is the EXACT antipattern at line 108-111 of the SP.';
PRINT '================================================================================';

DECLARE @debug_off bit = 'false';
DECLARE @debug_on  bit = 'true';
DECLARE @rc_off    int;
DECLARE @rc_on     int;

IF OBJECT_ID('tempdb..#test_off', 'U') IS NOT NULL DROP TABLE #test_off;
IF OBJECT_ID('tempdb..#test_on',  'U') IS NOT NULL DROP TABLE #test_on;

CREATE TABLE #seed_rows (i int);
INSERT INTO #seed_rows VALUES (1),(2),(3);

-- Path A: debug=false (production default).  IF body NOT executed.
SELECT * INTO #test_off FROM #seed_rows;
IF @debug_off = 'true' SELECT * FROM #test_off;
SELECT @rc_off = @@ROWCOUNT;

-- Path B: debug=true.  IF body IS executed (a 3-row SELECT).
SELECT * INTO #test_on FROM #seed_rows;
IF @debug_on  = 'true' SELECT * FROM #test_on;
SELECT @rc_on  = @@ROWCOUNT;

SELECT
    @rc_off AS rowcount_when_debug_false,
    @rc_on  AS rowcount_when_debug_true,
    'Both temp tables have 3 rows; only debug=true reports it correctly' AS note;
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 4a: EXEC sp_hepatitis_datamart_postprocessing with @debug=0 (production)';
PRINT '          Expect step-3 row_count = 0 in job_flow_log (LOGGING BUG).';
PRINT '          But downstream step row_counts (4-18) all = 1, proving the';
PRINT '          temp table WAS populated.';
PRINT '================================================================================';

DECLARE @batch_floor_a BIGINT = (SELECT ISNULL(MAX(batch_id), 0) FROM dbo.job_flow_log);

EXEC dbo.sp_hepatitis_datamart_postprocessing @phc_id = N'20000100', @debug = 0;

SELECT
    'debug_off' AS run_mode,
    batch_id, step_number, step_name, row_count
FROM dbo.job_flow_log
WHERE dataflow_name = 'HEPATITIS_DATAMART'
  AND batch_id > @batch_floor_a
ORDER BY step_number;
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 4b: EXEC sp_hepatitis_datamart_postprocessing with @debug=1';
PRINT '          Now step-3 row_count = 1 in job_flow_log (matches truth).';
PRINT '          Side-by-side comparison confirms the difference is purely the';
PRINT '          @debug branch in line 108, not any data-visibility issue.';
PRINT '================================================================================';

DECLARE @batch_floor_b BIGINT = (SELECT ISNULL(MAX(batch_id), 0) FROM dbo.job_flow_log);

EXEC dbo.sp_hepatitis_datamart_postprocessing @phc_id = N'20000100', @debug = 1;

SELECT
    'debug_on' AS run_mode,
    batch_id, step_number, step_name, row_count
FROM dbo.job_flow_log
WHERE dataflow_name = 'HEPATITIS_DATAMART'
  AND batch_id > @batch_floor_b
ORDER BY step_number;
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 5: Bug 5b — show why HEPATITIS_DATAMART stays empty even though';
PRINT '         #TMP_F_PAGE_CASE is correctly populated.';
PRINT '         The chain: nrt_investigation.patient_id NULL ->';
PRINT '         F_PAGE_CASE.PATIENT_KEY = 1 (sentinel via COALESCE) ->';
PRINT '         D_PATIENT.PATIENT_KEY=1 has PATIENT_UID NULL ->';
PRINT '         #TMP_D_Patient.PATIENT_UID NULL ->';
PRINT '         #TMP_HEPATITIS_CASE_BASE row deleted by line 2149.';
PRINT '================================================================================';

PRINT '5.1 nrt_investigation.patient_id for the foundation (expect NULL):';
SELECT public_health_case_uid, patient_id, investigator_id, person_as_reporter_uid,
       physician_id, hospital_uid, organization_id, ordering_facility_uid
FROM dbo.nrt_investigation WITH(NOLOCK)
WHERE public_health_case_uid = 20000100;

PRINT '';
PRINT '5.2 F_PAGE_CASE PATIENT_KEY (expect = 1, the sentinel):';
SELECT INVESTIGATION_KEY, CONDITION_KEY, PATIENT_KEY
FROM dbo.F_PAGE_CASE WITH(NOLOCK);

PRINT '';
PRINT '5.3 D_PATIENT row at sentinel key 1 (expect PATIENT_UID NULL):';
SELECT PATIENT_KEY, PATIENT_UID, PATIENT_LOCAL_ID
FROM dbo.D_PATIENT WITH(NOLOCK)
WHERE PATIENT_KEY = 1;

PRINT '';
PRINT '5.4 HEPATITIS_DATAMART final state (expect 0 rows):';
SELECT COUNT(*) AS hepatitis_datamart_rows FROM dbo.HEPATITIS_DATAMART WITH(NOLOCK);
GO

PRINT '';
PRINT '================================================================================';
PRINT 'STEP 6: Confirm narrowed scope.  Only sp_hepatitis_datamart_postprocessing';
PRINT '         uses #TMP_F_PAGE_CASE.  The 9 other SPs do NOT.';
PRINT '         Counts of #TMP_F_PAGE_CASE references per SP source body.';
PRINT '================================================================================';

SELECT
    name AS sp_name,
    (LEN(definition) - LEN(REPLACE(definition, '#TMP_F_PAGE_CASE', ''))) / LEN('#TMP_F_PAGE_CASE') AS tmp_f_page_case_refs
FROM sys.sql_modules sm
INNER JOIN sys.objects o ON o.object_id = sm.object_id
WHERE name IN (
    'sp_hepatitis_datamart_postprocessing',
    'sp_tb_datamart_postprocessing',
    'sp_var_datamart_postprocessing',
    'sp_covid_case_datamart_postprocessing',
    'sp_pertussis_case_datamart_postprocessing',
    'sp_measles_case_datamart_postprocessing',
    'sp_rubella_case_datamart_postprocessing',
    'sp_std_hiv_datamart_postprocessing',
    'sp_bmird_strep_pneumo_datamart_postprocessing',
    'sp_crs_case_datamart_postprocessing'
)
ORDER BY tmp_f_page_case_refs DESC, name;
GO

PRINT '';
PRINT '================================================================================';
PRINT 'END OF REPRO';
PRINT '================================================================================';
