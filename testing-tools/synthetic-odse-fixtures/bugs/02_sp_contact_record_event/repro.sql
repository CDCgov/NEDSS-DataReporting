/*
================================================================================
RTR Bug #2 — Self-contained reproduction
sp_contact_record_event references nbs_odse.dbo.fn_get_value_by_cd_codeset
(function actually lives in RDB_MODERN.dbo)
================================================================================

Reproduces the parse-time error:
    Msg 208, Level 16, State 1, ... Procedure dbo.sp_contact_record_event, Line 52
    Invalid object name 'nbs_odse.dbo.fn_get_value_by_cd_codeset'.

How to run (sqlcmd on localhost:3433):
    export SQLCMDPASSWORD=PizzaIsGood33!
    sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql

Inputs:
    @cc_uids = '20000170,20120010'
        - 20000170 = foundation Contact UID (from comparison-fixtures 00_foundation.sql)
        - 20120010 = v2 Contact UID (from comparison-fixtures 02_contact.sql)

Expected outcome:
    The EXEC fails at parse time. SQL Server attempts to bind the entire SELECT
    list (including the function call inside the CASE branch at line 69 of the
    SP source) BEFORE evaluating any row, so the CASE-gate on
    cc.CONTACT_STATUS being NULL/empty does NOT short-circuit the parser
    error. The SP cannot run against ANY input.
================================================================================
*/

SET NOCOUNT ON;
USE RDB_MODERN;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 1: Verify the function actually lives in RDB_MODERN.dbo, not nbs_odse.dbo';
PRINT '--------------------------------------------------------------------------------';

SELECT 'nbs_odse'   AS database_nm, name, type_desc FROM nbs_odse.sys.objects   WHERE name = 'fn_get_value_by_cd_codeset'
UNION ALL
SELECT 'RDB_MODERN' AS database_nm, name, type_desc FROM RDB_MODERN.sys.objects WHERE name = 'fn_get_value_by_cd_codeset'
UNION ALL
SELECT 'nbs_srte'   AS database_nm, name, type_desc FROM nbs_srte.sys.objects   WHERE name = 'fn_get_value_by_cd_codeset'
UNION ALL
SELECT 'RDB'        AS database_nm, name, type_desc FROM RDB.sys.objects        WHERE name = 'fn_get_value_by_cd_codeset'
UNION ALL
SELECT 'NBS_MSGOUTE' AS database_nm, name, type_desc FROM NBS_MSGOUTE.sys.objects WHERE name = 'fn_get_value_by_cd_codeset';

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 2: Confirm the SP source still references nbs_odse.dbo.fn_get_value_by_cd_codeset';
PRINT '--------------------------------------------------------------------------------';

SELECT
    OBJECT_NAME(sm.object_id)    AS sp_name,
    CHARINDEX('nbs_odse.dbo.fn_get_value_by_cd_codeset', sm.definition) AS char_offset_of_bad_ref
FROM RDB_MODERN.sys.sql_modules sm
WHERE sm.object_id = OBJECT_ID('RDB_MODERN.dbo.sp_contact_record_event');

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 3: EXEC the SP with sane inputs — expect Msg 208 (Invalid object name)';
PRINT '         The CASE-gate on cc.CONTACT_STATUS does NOT short-circuit parser binding.';
PRINT '--------------------------------------------------------------------------------';

BEGIN TRY
    EXEC RDB_MODERN.dbo.sp_contact_record_event
        @cc_uids = N'20000170,20120010',
        @debug   = 0;
END TRY
BEGIN CATCH
    -- Note: Msg 208 (deferred name resolution failure) typically aborts the
    -- batch and is NOT caught by TRY/CATCH inside the same scope as the EXEC
    -- in all SQL Server versions. Whether or not the CATCH fires, the error
    -- is surfaced to the client, which is the bug we are demonstrating.
    SELECT
        ERROR_NUMBER()    AS error_number,
        ERROR_SEVERITY()  AS error_severity,
        ERROR_STATE()     AS error_state,
        ERROR_PROCEDURE() AS error_procedure,
        ERROR_LINE()      AS error_line,
        ERROR_MESSAGE()   AS error_message;
END CATCH;

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 4: Demonstrate the fix works — same call but qualified to RDB_MODERN.dbo';
PRINT '         (read-only SELECT against the function with NULL input)';
PRINT '--------------------------------------------------------------------------------';

-- This succeeds because the function exists at this 3-part name.
SELECT * FROM RDB_MODERN.dbo.fn_get_value_by_cd_codeset(N'A', N'INV109');

-- And the unqualified (2-part) call works when run from RDB_MODERN context,
-- which is how the SP body should be calling it (matches the pattern used by
-- sp_investigation_event-001.sql, the only other RTR SP that calls this fn):
SELECT * FROM dbo.fn_get_value_by_cd_codeset(N'A', N'INV109');

GO
