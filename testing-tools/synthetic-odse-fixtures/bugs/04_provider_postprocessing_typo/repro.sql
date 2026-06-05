/*
================================================================================
RTR Bug #4 — Self-contained reproduction
sp_nrt_provider_postprocessing line 564 typo:
  #PATIENT_UPDATE_LIST should be #PROVIDER_UPDATE_LIST
================================================================================

Reproduces the runtime error:
    Msg 208, Level 16, State 0,
    Procedure dbo.sp_nrt_provider_postprocessing, Line 545
    Invalid object name '#PATIENT_UPDATE_LIST'.

  (SQL Server reports the line as 545 — the start of the IF EXISTS block
  containing the bad reference — because the binder fails the entire batch
  while resolving names for that statement. The actual offending token is on
  source-file line 564 of:
    NEDSS-DataReporting/liquibase-service/src/main/resources/
       db/005-rdb_modern/routines/003-sp_nrt_provider_postprocessing-001.sql)

How to run (sqlcmd on localhost:3433):
    export SQLCMDPASSWORD=PizzaIsGood33!
    sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql

Required state:
    - dbo.nrt_provider must contain rows for UID 20000010 (foundation Provider)
      and 20010010 (v2 Provider). These are seeded by
      utilities/comparison-fixtures/fixtures/10_subjects/provider.sql
      (foundation UID 20000010, v2 UID 20010010 per coverage_provider.md).
    - dbo.D_PROVIDER must already contain rows for those UIDs (i.e.
      sp_nrt_provider_postprocessing has been run against them at least once,
      taking the INSERT path). The Tier 1 Provider canary leaves the DB in
      exactly this state.

Why this bug is LATENT in baseline 6.0.18.1:
    - SQL Server uses *deferred name resolution* for # temp tables, so
      CREATE PROCEDURE binds successfully even with the typo.
    - The bad reference at line 564 lives inside an IF EXISTS gate (lines
      544-551) that is only entered when at least one row in
      #PROVIDER_UPDATE_LIST has datamart_update + tb_datamart_update +
      morbidity_datamart_update + std_hiv_datamart_update +
      hep100_datamart_update >= 1.
    - #PROVIDER_UPDATE_LIST is built (line 273) by joining
      D_PROVIDER p INNER JOIN #temp_prv_table tpt ON tpt.provider_key =
      p.provider_key. Each datamart_update flag is a CASE that compares
      staging-row attributes (tpt.*) against the existing dimension row (p.*).
    - On a clean INSERT path (D_PROVIDER row does not yet exist for the UID),
      the inner join produces 0 rows; IF EXISTS is false; the typo is never
      bound; the SP completes.
    - On an UPDATE re-run where staging values match the dim row exactly, all
      five CASEs evaluate to 0; IF EXISTS is false; same outcome.
    - On an UPDATE re-run with a meaningful diff (e.g. last_name changed),
      at least one CASE is 1, IF EXISTS is true, and the binder is forced to
      resolve #PATIENT_UPDATE_LIST inside the SELECT ... FOR JSON PATH. That
      temp table was never created in this SP; only #PROVIDER_UPDATE_LIST
      exists. Msg 208 fires and aborts the batch.

This script demonstrates all four states:
    STEP 1: Static-extract — show the typo at line 564 vs the correct
            declaration at line 273 of the SP source as stored in
            sys.sql_modules.
    STEP 2: Confirm INSERT-only path is clean (re-run SP with staging
            matching dim — no error).
    STEP 3: Wrap a meaningful mutation in a transaction, re-run the SP,
            capture Msg 208, and ROLLBACK so the DB state is unchanged.
    STEP 4: Suggested fix (one-line rename) shown as a comment.
================================================================================
*/

SET NOCOUNT ON;
USE RDB_MODERN;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 1: Static extract — confirm the typo is still in the SP body.';
PRINT '         Expected: 1 hit for #PATIENT_UPDATE_LIST (the typo) and';
PRINT '                   1 hit for #PROVIDER_UPDATE_LIST (the correct name).';
PRINT '--------------------------------------------------------------------------------';

SELECT
    OBJECT_NAME(sm.object_id)                                         AS sp_name,
    (LEN(sm.definition) - LEN(REPLACE(sm.definition, '#PATIENT_UPDATE_LIST', '')))
        / LEN('#PATIENT_UPDATE_LIST')                                 AS bad_ref_count,
    (LEN(sm.definition) - LEN(REPLACE(sm.definition, '#PROVIDER_UPDATE_LIST', '')))
        / LEN('#PROVIDER_UPDATE_LIST')                                AS good_ref_count,
    CHARINDEX('#PATIENT_UPDATE_LIST',  sm.definition)                 AS bad_ref_char_offset,
    CHARINDEX('#PROVIDER_UPDATE_LIST', sm.definition)                 AS good_ref_char_offset
FROM sys.sql_modules sm
WHERE sm.object_id = OBJECT_ID('dbo.sp_nrt_provider_postprocessing');
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 2: INSERT-only / no-diff path is clean.';
PRINT '         Re-run the SP against an existing UID with staging == dim.';
PRINT '         IF EXISTS at line 544 evaluates false; the binder never';
PRINT '         resolves #PATIENT_UPDATE_LIST; SP completes successfully.';
PRINT '--------------------------------------------------------------------------------';

BEGIN TRY
    EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20010010', @debug = 0;
    PRINT 'STEP 2 result: SP completed without Msg 208 (IF EXISTS short-circuited binding).';
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER()    AS error_number,
        ERROR_LINE()      AS error_line,
        ERROR_PROCEDURE() AS error_procedure,
        ERROR_MESSAGE()   AS error_message,
        '!! UNEXPECTED — Step 2 should be clean if no diff exists' AS note;
END CATCH;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 3: UPDATE-with-meaningful-diff path fires the typo.';
PRINT '         Wrap the mutation in a transaction so DB state is restored on';
PRINT '         ROLLBACK regardless of error / no-error path.';
PRINT '         Expected: Msg 208 — Invalid object name ''#PATIENT_UPDATE_LIST''';
PRINT '--------------------------------------------------------------------------------';

PRINT '--- Pre-state: D_PROVIDER and nrt_provider for UID 20010010 ---';
SELECT 'D_PROVIDER'   AS source, PROVIDER_UID AS provider_uid, PROVIDER_LAST_NAME AS last_name
  FROM dbo.D_PROVIDER  WHERE PROVIDER_UID = 20010010
UNION ALL
SELECT 'nrt_provider' AS source, provider_uid,                last_name
  FROM dbo.nrt_provider WHERE provider_uid = 20010010;

BEGIN TRAN bug04_repro;

UPDATE dbo.nrt_provider
   SET last_name = N'BUG04_MUTATED'
 WHERE provider_uid = 20010010;

PRINT '--- After mutation (inside TRAN), nrt_provider.last_name <> D_PROVIDER.PROVIDER_LAST_NAME ---';
SELECT 'D_PROVIDER'   AS source, PROVIDER_UID AS provider_uid, PROVIDER_LAST_NAME AS last_name
  FROM dbo.D_PROVIDER  WHERE PROVIDER_UID = 20010010
UNION ALL
SELECT 'nrt_provider' AS source, provider_uid,                last_name
  FROM dbo.nrt_provider WHERE provider_uid = 20010010;

BEGIN TRY
    EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20010010', @debug = 0;
    PRINT '!! UNEXPECTED — Step 3 SP did NOT raise. Bug may have been fixed.';
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER()    AS error_number,
        ERROR_SEVERITY()  AS error_severity,
        ERROR_STATE()     AS error_state,
        ERROR_PROCEDURE() AS error_procedure,
        ERROR_LINE()      AS error_line_reported,
        ERROR_MESSAGE()   AS error_message,
        '564' AS actual_source_file_line,
        'sp_nrt_provider_postprocessing' AS sp,
        '003-sp_nrt_provider_postprocessing-001.sql' AS sp_source_file;
END CATCH;

IF @@TRANCOUNT > 0 ROLLBACK TRAN bug04_repro;

PRINT '--- After ROLLBACK: nrt_provider state restored (no DB mutation persisted) ---';
SELECT provider_uid, last_name FROM dbo.nrt_provider WHERE provider_uid = 20010010;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 4: Suggested fix';
PRINT '--------------------------------------------------------------------------------';
PRINT '  In:  liquibase-service/src/main/resources/db/005-rdb_modern/routines/';
PRINT '       003-sp_nrt_provider_postprocessing-001.sql';
PRINT '  At line 564, replace:';
PRINT '       FROM #PATIENT_UPDATE_LIST';
PRINT '  With:';
PRINT '       FROM #PROVIDER_UPDATE_LIST';
PRINT '  No other change required. The SELECT ... FOR JSON PATH at lines 557-566';
PRINT '  reads only the same columns (provider_uid, datamart_update, ...) that';
PRINT '  #PROVIDER_UPDATE_LIST already exposes (declared at line 273).';
GO
