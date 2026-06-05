/*
================================================================================
RTR Bug #7 - Self-contained reproduction
sp_nrt_ldf_dimensional_data_postprocessing produces 0 rows when @ldf_id_list
contains any ldf_uid whose metadata data_type is NOT in ('ST','CV','LIST_ST').

Source:    NEDSS-DataReporting/liquibase-service/src/main/resources/db/
           005-rdb_modern/routines/265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql
Baseline:  6.0.18.1 (RDB_MODERN, after merge_and_verify.sh + ldf_answers_tetanus
           fixture).
Run with:
    export SQLCMDPASSWORD=PizzaIsGood33!
    sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql

NOTE on relation to Bug #5:
The README initially hypothesized this was the same root cause as Bug #5
(TMP_F_PAGE_CASE family - WITH(NOLOCK)/transaction isolation). It is NOT.
The TMP_LDF_DATA step (#LDF_DATA in the SP source, line 622) never even runs
in the failing scenario. The SP exits early at line 157 (RETURN) when the
backfill_list guard at lines 136-158 finds any ldf_uid in @ldf_id_list that
did not survive the #LDF_META_DATA filter on data_type IN ('ST','CV','LIST_ST').
The early-RETURN guard treats "filtered out by data_type whitelist" as
"missing NRT record" and aborts the whole batch. Bug #5's root cause (NOLOCK
join visibility from inside a SP) is unrelated.

This repro:
  Step 1: Verifies pre-conditions
  Step 2: EXECs sp_nrt_ldf_dimensional_data_postprocessing and captures
          job_flow_log step row counts (only steps 0-2 will be present;
          subsequent steps never run because of the early RETURN)
  Step 3: Demonstrates the early-RETURN guard fires by inspecting the
          backfill_list directly
  Step 4: Manually replicates the SP's first 3 steps outside the SP. Shows:
          - Step 1 (#LDF_UID_LIST) returns 5
          - Step 2 (#LDF_META_DATA) returns 4 (one ldf_uid filtered by
            data_type='SUB' not being in the whitelist)
          - Step 3 (#LDF_DATA) - SP version (INNER JOIN nrt_srte_LDF_PAGE_SET):
            returns 0 because nrt_ldf_data.ldf_page_id is NULL
          - Step 3 (#LDF_DATA) - LEFT-JOIN version (proposed fix): returns 5

This script is read-only against LDF_DIMENSIONAL_DATA except for the EXEC in
Step 2. The SP itself early-RETURNs before any INSERT, so LDF_DIMENSIONAL_DATA
remains empty.
================================================================================
*/

SET NOCOUNT ON;
USE RDB_MODERN;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 1: Pre-conditions';
PRINT '--------------------------------------------------------------------------------';

-- 1a: nrt_ldf_data has 5 rows for the Tetanus Investigation
SELECT 'nrt_ldf_data rows for Tetanus PHC 22000200' AS metric, COUNT(*) AS row_count
FROM dbo.nrt_ldf_data WHERE business_object_uid = 22000200;

-- 1b: nrt_odse_state_defined_field_metadata has matching rows
SELECT 'matching nrt_odse_state_defined_field_metadata rows' AS metric, COUNT(*) AS row_count
FROM dbo.nrt_odse_state_defined_field_metadata m
INNER JOIN dbo.nrt_ldf_data n ON n.ldf_uid = m.ldf_uid
WHERE n.business_object_uid = 22000200;

-- 1c: LDF_DIMENSIONAL_DATA is empty (so any non-zero result post-EXEC is from this run)
SELECT 'LDF_DIMENSIONAL_DATA rows (expect 0)' AS metric, COUNT(*) AS row_count
FROM dbo.LDF_DIMENSIONAL_DATA;

-- 1d: Inv exists with the right cd
SELECT 'nrt_investigation 22000200 exists' AS metric, COUNT(*) AS row_count
FROM dbo.nrt_investigation WHERE public_health_case_uid = 22000200 AND cd = '10210';

-- 1e: LDF_DATAMART_TABLE_REF maps condition 10210 (so the WHERE in #LDF_META_DATA passes)
SELECT 'LDF_DATAMART_TABLE_REF entries for 10210' AS metric, COUNT(*) AS row_count
FROM dbo.LDF_DATAMART_TABLE_REF WHERE condition_cd = '10210';

-- 1f: Show the data_type breakdown for our 5 ldf_uids - this is the punch line
SELECT
    'data_type per ldf_uid' AS metric,
    n.ldf_uid,
    m.data_type,
    CASE WHEN m.data_type IN ('ST','CV','LIST_ST') THEN 'PASS' ELSE 'FAIL (drops row from #LDF_META_DATA)' END AS sp_filter_outcome
FROM dbo.nrt_ldf_data n
LEFT JOIN dbo.nrt_odse_state_defined_field_metadata m ON m.ldf_uid = n.ldf_uid
WHERE n.business_object_uid = 22000200
ORDER BY n.ldf_uid;

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 2: EXEC sp_nrt_ldf_dimensional_data_postprocessing and dump job_flow_log';
PRINT '         Expected: only steps 0-2 logged. SP exits early via RETURN at line 157.';
PRINT '--------------------------------------------------------------------------------';

DECLARE @ldf_uids nvarchar(max);
SELECT @ldf_uids = STRING_AGG(CAST(ldf_uid AS varchar), ',')
FROM dbo.nrt_ldf_data
WHERE business_object_uid = 22000200;

PRINT 'Calling SP with @ldf_id_list =';
PRINT @ldf_uids;

DECLARE @batch_before BIGINT = (SELECT ISNULL(MAX(batch_id), 0) FROM dbo.job_flow_log);

EXEC dbo.sp_nrt_ldf_dimensional_data_postprocessing @ldf_id_list = @ldf_uids, @debug = 0;

SELECT
    'sp_nrt_ldf_dimensional_data_postprocessing job_flow_log' AS info,
    step_number,
    step_name,
    row_count,
    status_type,
    LEFT(ISNULL(Msg_Description1, ''), 200) AS msg_description1
FROM dbo.job_flow_log
WHERE batch_id > @batch_before
  AND package_name = 'sp_nrt_ldf_dimensional_data_postprocessing'
ORDER BY step_number;

SELECT 'Final LDF_DIMENSIONAL_DATA rows (expect still 0)' AS metric, COUNT(*) AS row_count
FROM dbo.LDF_DIMENSIONAL_DATA;

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 3: Demonstrate the early-RETURN guard (lines 136-158 of the SP)';
PRINT '         The SP computes @backfill_list = ldf_uids in @ldf_id_list that are NOT';
PRINT '         in #LDF_META_DATA. If non-NULL, RETURN. The guard intends to detect';
PRINT '         missing NRT metadata rows but cannot distinguish between (a) truly';
PRINT '         missing and (b) intentionally filtered out by the data_type whitelist.';
PRINT '--------------------------------------------------------------------------------';

DECLARE @ldf_id_list nvarchar(max) =
    (SELECT STRING_AGG(CAST(ldf_uid AS varchar), ',')
     FROM dbo.nrt_ldf_data WHERE business_object_uid = 22000200);

IF OBJECT_ID('tempdb..#LDF_UID_LIST') IS NOT NULL DROP TABLE #LDF_UID_LIST;
SELECT DISTINCT TRIM(value) AS ldf_uid
INTO #LDF_UID_LIST
FROM STRING_SPLIT(@ldf_id_list, ',');

IF OBJECT_ID('tempdb..#LDF_META_DATA') IS NOT NULL DROP TABLE #LDF_META_DATA;
SELECT a.ldf_uid, a.business_object_nm, a.condition_cd, a.data_type
INTO #LDF_META_DATA
FROM dbo.nrt_odse_state_defined_field_metadata a WITH (NOLOCK)
LEFT OUTER JOIN dbo.nrt_srte_ldf_page_set page_set WITH (NOLOCK)
    ON page_set.ldf_page_id = a.ldf_page_id
INNER JOIN #LDF_UID_LIST l ON l.ldf_uid = a.ldf_uid
WHERE (a.condition_cd IN (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WITH (NOLOCK))
       OR a.condition_cd IS NULL)
  AND a.business_object_nm IN ('PHC','BMD','NIP','HEP')
  AND a.data_type IN ('ST','CV','LIST_ST');

DECLARE @backfill_list nvarchar(max) =
(
    SELECT string_agg(t.value, ',')
    FROM (SELECT DISTINCT TRIM(value) AS value FROM STRING_SPLIT(@ldf_id_list, ',')) t
    LEFT JOIN #LDF_META_DATA tmp ON tmp.ldf_uid = t.value
    WHERE tmp.ldf_uid IS NULL
);

SELECT 'backfill_list (non-NULL means SP would early-RETURN)' AS info, @backfill_list AS backfill_list;

-- And show what data_type that "missing" ldf_uid actually has - it has a metadata row,
-- it was just filtered out by the whitelist.
SELECT
    'metadata row for the "missing" ldf_uid (proves the row exists, just data_type filtered)' AS info,
    m.ldf_uid,
    m.business_object_nm,
    m.condition_cd,
    m.data_type
FROM dbo.nrt_odse_state_defined_field_metadata m
WHERE m.ldf_uid IN (SELECT TRIM(value) FROM STRING_SPLIT(@backfill_list, ','));

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 4: Manually replicate first 3 SP steps outside the SP scope';
PRINT '         Shows that even if the early-RETURN guard were removed, #LDF_DATA';
PRINT '         (the "TMP_LDF_DATA" step at line 622) would still return 0 rows from';
PRINT '         the SP version because nrt_ldf_data.ldf_page_id is NULL and the SP';
PRINT '         uses INNER JOIN to nrt_srte_LDF_PAGE_SET. Same JOIN done as LEFT JOIN';
PRINT '         (consistent with the metadata-step usage at line 107-111) returns 5.';
PRINT '--------------------------------------------------------------------------------';

DECLARE @ldf_id_list2 nvarchar(max) =
    (SELECT STRING_AGG(CAST(ldf_uid AS varchar), ',')
     FROM dbo.nrt_ldf_data WHERE business_object_uid = 22000200);

-- Step 1: #LDF_UID_LIST
IF OBJECT_ID('tempdb..#L1') IS NOT NULL DROP TABLE #L1;
SELECT DISTINCT TRIM(value) AS ldf_uid INTO #L1 FROM STRING_SPLIT(@ldf_id_list2, ',');
SELECT 'Manual Step 1 #LDF_UID_LIST count (expect 5)' AS info, COUNT(*) AS row_count FROM #L1;

-- Step 2: #LDF_META_DATA (mirrors lines 85-120 of SP)
IF OBJECT_ID('tempdb..#L2') IS NOT NULL DROP TABLE #L2;
SELECT a.ldf_uid, a.business_object_nm, a.condition_cd, a.data_type
INTO #L2
FROM dbo.nrt_odse_state_defined_field_metadata a WITH (NOLOCK)
LEFT OUTER JOIN dbo.nrt_srte_ldf_page_set page_set WITH (NOLOCK)
    ON page_set.ldf_page_id = a.ldf_page_id
INNER JOIN #L1 l ON l.ldf_uid = a.ldf_uid
WHERE (a.condition_cd IN (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WITH (NOLOCK))
       OR a.condition_cd IS NULL)
  AND a.business_object_nm IN ('PHC','BMD','NIP','HEP')
  AND a.data_type IN ('ST','CV','LIST_ST');
SELECT 'Manual Step 2 #LDF_META_DATA count (expect 4 - 1 row data_type=SUB filtered)' AS info, COUNT(*) AS row_count FROM #L2;

-- Step 3 (SP version): #LDF_DATA with INNER JOIN to nrt_srte_LDF_PAGE_SET
-- Mirrors lines 628-660 of the SP exactly.
IF OBJECT_ID('tempdb..#L3_SP') IS NOT NULL DROP TABLE #L3_SP;
SELECT a.ldf_uid, a.business_object_uid, a.ldf_value,
       page_set.code_short_desc_txt AS page_set
INTO #L3_SP
FROM dbo.nrt_ldf_data a WITH (NOLOCK)
INNER JOIN dbo.nrt_srte_LDF_PAGE_SET page_set WITH (NOLOCK)
    ON page_set.ldf_page_id = a.ldf_page_id
LEFT JOIN dbo.nrt_srte_Codeset c WITH (NOLOCK) ON a.code_set_nm = c.code_set_nm
INNER JOIN dbo.nrt_INVESTIGATION inv WITH (NOLOCK)
    ON a.business_object_uid = inv.public_health_case_uid
INNER JOIN dbo.LDF_DATAMART_TABLE_REF b WITH (NOLOCK) ON inv.cd = b.condition_cd
INNER JOIN #L1 l ON l.ldf_uid = a.ldf_uid;

SELECT 'Manual Step 3 #LDF_DATA SP-VERSION (INNER JOIN page_set) count (expect 0)' AS info,
       COUNT(*) AS row_count FROM #L3_SP;

-- Step 3 (FIX version): same query with LEFT JOIN to nrt_srte_LDF_PAGE_SET
-- (consistent with how the same join is done in #LDF_META_DATA at SP line 107-111)
IF OBJECT_ID('tempdb..#L3_FIX') IS NOT NULL DROP TABLE #L3_FIX;
SELECT a.ldf_uid, a.business_object_uid, a.ldf_value,
       page_set.code_short_desc_txt AS page_set
INTO #L3_FIX
FROM dbo.nrt_ldf_data a WITH (NOLOCK)
LEFT JOIN dbo.nrt_srte_LDF_PAGE_SET page_set WITH (NOLOCK)
    ON page_set.ldf_page_id = a.ldf_page_id
LEFT JOIN dbo.nrt_srte_Codeset c WITH (NOLOCK) ON a.code_set_nm = c.code_set_nm
INNER JOIN dbo.nrt_INVESTIGATION inv WITH (NOLOCK)
    ON a.business_object_uid = inv.public_health_case_uid
INNER JOIN dbo.LDF_DATAMART_TABLE_REF b WITH (NOLOCK) ON inv.cd = b.condition_cd
INNER JOIN #L1 l ON l.ldf_uid = a.ldf_uid;

SELECT 'Manual Step 3 #LDF_DATA FIX-VERSION (LEFT JOIN page_set) count (expect 5)' AS info,
       COUNT(*) AS row_count FROM #L3_FIX;
SELECT 'Sample rows from FIX-VERSION:' AS info, * FROM #L3_FIX;

-- Show that nrt_ldf_data.ldf_page_id is NULL for our fixture rows -- this is why
-- the INNER JOIN drops them. (The nrt_odse_state_defined_field_metadata side has
-- ldf_page_id populated; the nrt_ldf_data side does not.)
SELECT 'nrt_ldf_data.ldf_page_id values (expect all NULL)' AS info,
       ldf_uid, ldf_page_id
FROM dbo.nrt_ldf_data WHERE business_object_uid = 22000200
ORDER BY ldf_uid;

GO

PRINT '';
PRINT '--- end Bug #7 repro ---';
GO
