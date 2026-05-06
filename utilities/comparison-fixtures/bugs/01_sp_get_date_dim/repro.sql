-- ===========================================================================
-- Bug #1 repro: dbo.sp_get_date_dim references nonexistent dbo.rdb_date_temp
-- ===========================================================================
--
-- Source:    NEDSS-DataReporting/liquibase-service/src/main/resources/db/
--            005-rdb_modern/routines/014-sp_get_date_dim-001.sql
-- Baseline:  6.0.18.1 (RDB_MODERN, freshly liquibase-applied)
-- Run with:  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
--                  -d RDB_MODERN -i repro.sql
--
-- Expected:  SP errors with Msg 208, Level 16:
--                Invalid object name 'dbo.rdb_date_temp'
--            on the very first statement of its body that touches that name
--            (line 26 of the SP source: the `if not exists (select * from
--            dbo.rdb_date_temp ...)` on the default-row guard).
--
-- This script is read-only. It does NOT create dbo.rdb_date_temp, does NOT
-- INSERT/UPDATE/DELETE anything in RDB_DATE, and does NOT modify any other
-- agent's working state. It only EXECs the SP and observes the catalog.
-- ===========================================================================

USE RDB_MODERN;
GO

PRINT '--- Bug #1 repro: dbo.sp_get_date_dim ---';
PRINT '';

-- Pre-condition #1: the SP exists.
PRINT 'Pre-condition: dbo.sp_get_date_dim object_id =';
SELECT OBJECT_ID(N'dbo.sp_get_date_dim') AS sp_get_date_dim_object_id;

-- Pre-condition #2: the table the SP references does NOT exist anywhere
--                   in the catalog (the bug).
PRINT 'Pre-condition: dbo.rdb_date_temp object_id (expect NULL) =';
SELECT OBJECT_ID(N'dbo.rdb_date_temp') AS rdb_date_temp_object_id;

-- Pre-condition #3: the table the SP is *supposed* to populate (RDB_DATE)
--                   does exist.
PRINT 'Pre-condition: dbo.RDB_DATE object_id =';
SELECT OBJECT_ID(N'dbo.RDB_DATE') AS RDB_DATE_object_id;

PRINT '';
PRINT '--- Now invoking sp_get_date_dim 2026, 2026 (one-year range, sane args) ---';
PRINT '--- Expected: Msg 208 Invalid object name ''dbo.rdb_date_temp''       ---';
PRINT '';

-- Wrap in TRY/CATCH so we (a) capture the SqlServer error number/state and
-- (b) keep going to print a post-condition. Without TRY/CATCH sqlcmd would
-- still surface the error to stderr, but we want a clean structured
-- diagnostic line in stdout for the bug report.
BEGIN TRY
    EXEC dbo.sp_get_date_dim @start = 2026, @end = 2026;
    PRINT 'UNEXPECTED: sp_get_date_dim returned without raising an error.';
END TRY
BEGIN CATCH
    PRINT 'Caught error from sp_get_date_dim:';
    SELECT
        ERROR_NUMBER()    AS error_number,
        ERROR_SEVERITY()  AS error_severity,
        ERROR_STATE()     AS error_state,
        ERROR_PROCEDURE() AS error_procedure,
        ERROR_LINE()      AS error_line,
        ERROR_MESSAGE()   AS error_message;
END CATCH;

PRINT '';
PRINT '--- Post-condition: confirm dbo.rdb_date_temp still does not exist ---';
SELECT OBJECT_ID(N'dbo.rdb_date_temp') AS rdb_date_temp_object_id_after;

PRINT '';
PRINT '--- end repro ---';
GO
