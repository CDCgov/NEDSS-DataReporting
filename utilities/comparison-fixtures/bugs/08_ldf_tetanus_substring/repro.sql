/*
================================================================================
RTR Bug #8 -- Self-contained reproduction
sp_ldf_tetanus_datamart_postprocessing line 824:
    "Invalid length parameter passed to LEFT or SUBSTRING function"
================================================================================

Source SP: NEDSS-DataReporting/liquibase-service/src/main/resources/db/
           005-rdb_modern/routines/300-sp_ldf_tetanus_datamart_postprocessing-001.sql

The offending statement is at line 833 of the source file:

    SET  @dynamiccolumnUpdate = substring(@dynamiccolumnUpdate, 1,
                                          len(@dynamiccolumnUpdate) - 1)

(SQL Server reports the error at line 824, the BEGIN TRANSACTION that opens the
"UPDATE LDF_TETANUS when there is no record in the LDF_DIMENSIONAL_DATA" block.
The numeric offset varies a couple of lines depending on how the SP definition
counts whitespace; both 824 and 833 point at the same logical statement.)

Root cause (no LDF answer columns on LDF_TETANUS):
    The block at lines 822-844 builds a NULL-out UPDATE statement by
    concatenating column names from LDF_TETANUS that are NOT in the 7-element
    baseline-key exclusion list:
        INVESTIGATION_KEY, INVESTIGATION_LOCAL_ID, PROGRAM_JURISDICTION_OID,
        PATIENT_KEY, PATIENT_LOCAL_ID, DISEASE_NAME, DISEASE_CD.
    Those 7 baseline keys are the ONLY columns LDF_TETANUS has at liquibase-
    apply time. Dynamic LDF answer columns are added later, conditionally,
    by an `ALTER TABLE LDF_TETANUS ADD ...` at line 714 of the SP -- but only
    when #MISSED_COLS is non-empty, which requires LDF_DIMENSIONAL_DATA to
    contain rows for the input investigations.
    When LDF_DIMENSIONAL_DATA is empty (the current state, courtesy of Bug #7),
    no ALTER TABLE runs, LDF_TETANUS still has only the 7 baseline columns,
    the SELECT at line 829 produces zero rows, @dynamiccolumnUpdate stays as
    the empty string '', LEN('') = 0, LEN('') - 1 = -1, and SUBSTRING('', 1, -1)
    raises Msg 537 "Invalid length parameter passed to the LEFT or SUBSTRING
    function".

How to run (sqlcmd on localhost:3433):
    export SQLCMDPASSWORD=...    # required, not stored in this file
    sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql

Inputs:
    @phc_id_list = N'22000200'   -- Tetanus Investigation case UID
                                    (condition_cd='10210', seeded by
                                    fixtures/30_sp_coverage/ldf_answers_tetanus.sql)
    @debug       = 0

Expected outcome:
    The SP catches its own error in its outer TRY/CATCH and writes a row to
    [dbo].[job_flow_log] tagged 'Error' with:
        Error Number  : 537
        Error Severity: 16
        Error State   : 3
        Error Line    : 824
        Error Message : Invalid length parameter passed to the LEFT or
                        SUBSTRING function.
    The catch handler also re-raises a single output row whose `stored_procedure`
    column carries the same Error_Line/Error_Message text. LDF_TETANUS remains
    empty and unchanged.

This script is read-only with respect to durable state. It does not modify the
LDF_TETANUS table definition, does not insert into LDF_DIMENSIONAL_DATA, and
does not change any RTR routine source. The SP itself writes diagnostic rows
into [dbo].[job_flow_log] -- that is the SP's own behavior, not this script's.
================================================================================
*/

SET NOCOUNT ON;
USE RDB_MODERN;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 1: Pre-conditions -- verify the upstream state that triggers the bug.';
PRINT '--------------------------------------------------------------------------------';

-- Pre-condition 1: the SP exists.
PRINT '  sp_ldf_tetanus_datamart_postprocessing object_id (expect non-NULL):';
SELECT OBJECT_ID(N'dbo.sp_ldf_tetanus_datamart_postprocessing')
       AS sp_ldf_tetanus_datamart_postprocessing_object_id;

-- Pre-condition 2: LDF_DIMENSIONAL_DATA is empty (Bug #7 outcome).
PRINT '  LDF_DIMENSIONAL_DATA row count (expect 0 -- this is Bug #7''s symptom):';
SELECT COUNT(*) AS LDF_DIMENSIONAL_DATA_count FROM dbo.LDF_DIMENSIONAL_DATA WITH (NOLOCK);

-- Pre-condition 3: LDF_TETANUS exists but has only the 7 baseline-key columns
--                  (no dynamic LDF answer columns have been ALTER-TABLE-added yet).
PRINT '  LDF_TETANUS row count (expect 0):';
SELECT COUNT(*) AS LDF_TETANUS_count FROM dbo.LDF_TETANUS WITH (NOLOCK);

PRINT '  LDF_TETANUS column inventory -- ALL columns (expect ONLY the 7 baseline keys):';
SELECT COLUMN_NAME, ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'LDF_TETANUS'
ORDER BY ORDINAL_POSITION;

PRINT '  LDF_TETANUS columns that are NOT in the 7-element baseline exclusion list';
PRINT '  -- this is exactly the SELECT that line 829 of the SP runs to build';
PRINT '  @dynamiccolumnUpdate. Expect ZERO rows -> @dynamiccolumnUpdate stays empty.';
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'LDF_TETANUS'
  AND COLUMN_NAME NOT IN (
      'INVESTIGATION_KEY', 'INVESTIGATION_LOCAL_ID', 'PROGRAM_JURISDICTION_OID',
      'PATIENT_KEY', 'PATIENT_LOCAL_ID', 'DISEASE_NAME', 'DISEASE_CD'
  );

-- Pre-condition 4: the Tetanus Investigation we are pointing the SP at exists.
PRINT '  Tetanus Investigation INVESTIGATION_KEY for CASE_UID 22000200 (expect a key):';
SELECT INVESTIGATION_KEY, CASE_UID
FROM dbo.INVESTIGATION WITH (NOLOCK)
WHERE CASE_UID = 22000200;
GO

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 2: Demonstrate the bug locally -- reproduce the same statement the SP';
PRINT '        runs at line 833, with the same inputs the SP would have at runtime.';
PRINT '--------------------------------------------------------------------------------';

DECLARE @dynamiccolumnUpdate VARCHAR(MAX) = '';

SELECT @dynamiccolumnUpdate = @dynamiccolumnUpdate + 'TBL.[' + COLUMN_NAME + '] = NULL ,'
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = 'LDF_TETANUS'
  AND  COLUMN_NAME NOT IN (
       'INVESTIGATION_KEY', 'INVESTIGATION_LOCAL_ID', 'PROGRAM_JURISDICTION_OID',
       'PATIENT_KEY', 'PATIENT_LOCAL_ID', 'DISEASE_NAME', 'DISEASE_CD'
  );

PRINT '  @dynamiccolumnUpdate after the SELECT (expect empty string):';
SELECT
    LEN(@dynamiccolumnUpdate)               AS len_value,        -- expect 0
    LEN(@dynamiccolumnUpdate) - 1           AS len_minus_1,      -- expect -1
    '[' + @dynamiccolumnUpdate + ']'        AS bracketed_value;  -- expect "[]"

PRINT '  Now invoke the same SUBSTRING the SP runs at line 833 -- expect Msg 537.';
BEGIN TRY
    SET @dynamiccolumnUpdate = SUBSTRING(@dynamiccolumnUpdate,
                                         1,
                                         LEN(@dynamiccolumnUpdate) - 1);
    PRINT '    UNEXPECTED: SUBSTRING returned without raising Msg 537.';
END TRY
BEGIN CATCH
    PRINT '    Caught the exact error the SP catches:';
    SELECT
        ERROR_NUMBER()    AS error_number,    -- expect 537
        ERROR_SEVERITY()  AS error_severity,  -- expect 16
        ERROR_STATE()     AS error_state,     -- expect 3
        ERROR_PROCEDURE() AS error_procedure, -- NULL (we are not inside a SP)
        ERROR_LINE()      AS error_line,
        ERROR_MESSAGE()   AS error_message;   -- expect "Invalid length ..."
END CATCH;
GO

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 3: EXEC the real SP -- it has its own outer TRY/CATCH so it will not';
PRINT '        bubble Msg 537 to the client; instead it writes an Error row to';
PRINT '        job_flow_log and returns one diagnostic result-set row whose';
PRINT '        `stored_procedure` column carries the Error_Line/Error_Message text.';
PRINT '--------------------------------------------------------------------------------';

DECLARE @before_log_max_id BIGINT;
SELECT @before_log_max_id = ISNULL(MAX(record_id), 0) FROM dbo.job_flow_log;

EXEC dbo.sp_ldf_tetanus_datamart_postprocessing
     @phc_id_list = N'22000200',
     @debug       = 0;

PRINT '  job_flow_log rows written by THIS SP invocation, filtered to Error rows:';
SELECT
    record_id,
    batch_id,
    [Dataflow_Name],
    [package_Name],
    [Status_Type],
    [step_number],
    [step_name],
    LEFT(ISNULL([Msg_Description1], ''), 400) AS msg_description1_truncated
FROM dbo.job_flow_log
WHERE record_id > @before_log_max_id
  AND ([Status_Type] = 'Error' OR [step_name] LIKE '%Error%' OR [Msg_Description1] LIKE '%Error%')
ORDER BY record_id;
GO

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 4: Post-condition -- LDF_TETANUS is still empty, still 7 columns,';
PRINT '        the SP made no progress.';
PRINT '--------------------------------------------------------------------------------';

SELECT COUNT(*) AS LDF_TETANUS_count_after FROM dbo.LDF_TETANUS WITH (NOLOCK);

SELECT COUNT(*) AS LDF_TETANUS_column_count_after
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'LDF_TETANUS';
GO

PRINT '';
PRINT '--- end Bug #8 repro ---';
GO
