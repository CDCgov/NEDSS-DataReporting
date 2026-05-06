/*
================================================================================
RTR Bug #6 - Self-contained reproduction
sp_nrt_ldf_postprocessing maps nrt_ldf_data.metadata_record_status_cd
(varchar(20), holds 'LDF_PROCESSED' = 13 chars) into LDF_DATA.RECORD_STATUS_CD
(varchar(8) with CHECK CONSTRAINT IN ('ACTIVE','INACTIVE'))
================================================================================

SP source:    NEDSS-DataReporting/liquibase-service/src/main/resources/db/
              005-rdb_modern/routines/015-sp_nrt_ldf_postprocessing-001.sql
Lines:        1097-1115 (INSERT column list), 1116-1138 (SELECT mapping;
              line 1132 maps tld.metadata_record_status_cd -> RECORD_STATUS_CD)

Table sources:
              tables/226-create_ldf_data-001.sql
                  RECORD_STATUS_CD VARCHAR(8) NOT NULL
                  CONSTRAINT CHK_LDFDATA_RECORD_STATUS
                      CHECK(RECORD_STATUS_CD IN ('ACTIVE','INACTIVE'))
              tables/018-create_nrt_ldf_data-001.sql
                  metadata_record_status_cd  varchar(20)  NULL
              tables/246-create_nrt_odse_state_defined_field_metadata-001.sql
                  record_status_cd  varchar(20) NOT NULL
                  -- All 2754 baseline rows hold the literal 'LDF_PROCESSED'
                  -- (13 chars). 'ACTIVE' is NOT a value the metadata uses.

How to run (sqlcmd on localhost:3433):
    export SQLCMDPASSWORD=...
    sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql

Expected outcome:
    The SP runs, the BEGIN TRAN/COMMIT for "Insert into LDF_GROUP Dimension"
    succeeds (creating an nrt_ldf_group_key + nrt_ldf_data_key + ldf_group
    row for our test business_object_uid), but the next BEGIN TRAN/COMMIT
    "Insert into LDF_DATA Dimension" fails with:

        Msg 2628, Level 16, State 1
        String or binary data would be truncated in table
        'RDB_MODERN.dbo.LDF_DATA', column 'RECORD_STATUS_CD'.
        Truncated value: 'LDF_PROCESSED'.

    The SP's outer BEGIN CATCH (line 1372) traps the error, rolls back the
    open transaction, logs to job_flow_log, and returns a single-row error
    result set. We surface that row plus the job_flow_log row.

This script is self-contained. It authors a single nrt_ldf_data row tied to
a fresh business_object_uid (29999999) that does not exist anywhere else in
the schema, runs the SP, captures the truncation error, and removes its own
rows on the way out so the DB state is unchanged after the script completes.

CRITICAL: this script does NOT modify any RTR routine or any other agent's
working state.
================================================================================
*/

SET NOCOUNT ON;
USE RDB_MODERN;
GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 1: Schema evidence -- column widths from INFORMATION_SCHEMA';
PRINT '--------------------------------------------------------------------------------';

SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH AS max_len
FROM INFORMATION_SCHEMA.COLUMNS
WHERE
    (TABLE_NAME = 'LDF_DATA'                              AND COLUMN_NAME = 'RECORD_STATUS_CD')
 OR (TABLE_NAME = 'nrt_ldf_data'                          AND COLUMN_NAME = 'metadata_record_status_cd')
 OR (TABLE_NAME = 'nrt_odse_state_defined_field_metadata' AND COLUMN_NAME = 'record_status_cd')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- The CHECK constraint on LDF_DATA.RECORD_STATUS_CD only permits
-- 'ACTIVE' or 'INACTIVE' (8 chars max), which is the design intent the
-- column width reflects.
SELECT
    cc.name             AS constraint_name,
    cc.definition       AS check_definition
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID('dbo.LDF_DATA')
  AND cc.name = 'CHK_LDFDATA_RECORD_STATUS';

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 2: Source-of-truth check -- baseline metadata uses LDF_PROCESSED, not ACTIVE';
PRINT '--------------------------------------------------------------------------------';

SELECT
    record_status_cd,
    LEN(record_status_cd)  AS char_len,
    COUNT(*)               AS row_count
FROM dbo.nrt_odse_state_defined_field_metadata
GROUP BY record_status_cd
ORDER BY row_count DESC;

GO

PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 3: Author one nrt_ldf_data row with the canonical metadata value';
PRINT '         (metadata_record_status_cd = ''LDF_PROCESSED'', 13 chars)';
PRINT '--------------------------------------------------------------------------------';

DECLARE @bo_uid       BIGINT       = 29999999;     -- fresh, unused business_object_uid
DECLARE @ldf_uid      BIGINT;
DECLARE @ldf_uid_csv  NVARCHAR(50);

-- Pick an unused baseline LDF UID so the SP's metadata join (line 869) succeeds.
SELECT TOP 1 @ldf_uid = md.ldf_uid
FROM dbo.nrt_odse_state_defined_field_metadata md
WHERE md.business_object_nm = 'PHC'
  AND md.condition_cd IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM dbo.nrt_ldf_data ld
      WHERE ld.ldf_uid = md.ldf_uid
        AND ld.business_object_uid = @bo_uid)
ORDER BY md.ldf_uid;

SET @ldf_uid_csv = CAST(@ldf_uid AS NVARCHAR(50));
PRINT 'Selected baseline ldf_uid: ' + @ldf_uid_csv;
PRINT 'Test business_object_uid:  ' + CAST(@bo_uid AS NVARCHAR(50));

INSERT INTO dbo.nrt_ldf_data
    (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
     active_ind, ldf_meta_data_business_object_nm,
     condition_cd, label_txt, data_type, code_set_nm,
     ldf_value, ldf_column_type,
     record_status_cd,                  -- nrt_ldf_data's own status (varchar(20))
     metadata_record_status_cd,         -- THE FIELD THAT TRIGGERS THE BUG
     ldf_data_field_add_time, ldf_data_last_chg_time,
     metadata_record_status_time, ldf_meta_data_add_time)
SELECT
    md.ldf_uid,
    @bo_uid,
    'PHC',
    'Y',
    md.business_object_nm,
    md.condition_cd,
    md.label_txt,
    md.data_type,
    md.code_set_nm,
    'Y',
    md.data_type,
    'ACTIVE',                           -- nrt_ldf_data.record_status_cd (controls SP filter)
    'LDF_PROCESSED',                    -- canonical value -> 13 chars -> truncates into varchar(8)
    '2026-04-01T00:00:00',
    '2026-04-01T00:00:00',
    '2026-04-01T00:00:00',
    '2026-04-01T00:00:00'
FROM dbo.nrt_odse_state_defined_field_metadata md
WHERE md.ldf_uid = @ldf_uid;

PRINT 'Inserted nrt_ldf_data row(s): ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 4: EXEC sp_nrt_ldf_postprocessing -- expect Msg 2628 truncation error';
PRINT '         caught by SP''s own BEGIN CATCH (line 1372 of the routine).';
PRINT '         The SP returns its diagnostic SELECT as the result set.';
PRINT '--------------------------------------------------------------------------------';

DECLARE @batch_id_before BIGINT = (SELECT ISNULL(MAX(batch_id), 0) FROM dbo.job_flow_log);

EXEC dbo.sp_nrt_ldf_postprocessing @ldf_uid_list = @ldf_uid_csv, @debug = 0;

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 5: Confirm the error is the truncation (Error 2628) by reading job_flow_log';
PRINT '--------------------------------------------------------------------------------';

SELECT
    batch_id,
    Status_Type,
    step_name,
    Error_Description
FROM dbo.job_flow_log
WHERE batch_id  > @batch_id_before
  AND package_Name = 'sp_nrt_ldf_postprocessing'
  AND Status_Type  = 'ERROR'
ORDER BY batch_id;

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 6: Confirm LDF_DATA contains NO row for our test business_object_uid';
PRINT '         (because the INSERT was rolled back by the BEGIN CATCH)';
PRINT '         BUT nrt_ldf_data_key / nrt_ldf_group_key / ldf_group rows DID commit';
PRINT '         in their earlier per-step transactions (lines 1039-1065 of the SP).';
PRINT '--------------------------------------------------------------------------------';

SELECT 'LDF_DATA'             AS tbl, COUNT(*) AS rows_for_test_bo_uid
FROM dbo.LDF_DATA ld
JOIN dbo.nrt_ldf_data_key k ON ld.ldf_data_key = k.d_ldf_data_key
WHERE k.business_object_uid = @bo_uid
UNION ALL
SELECT 'nrt_ldf_data_key',       COUNT(*) FROM dbo.nrt_ldf_data_key  WHERE business_object_uid = @bo_uid
UNION ALL
SELECT 'nrt_ldf_group_key',      COUNT(*) FROM dbo.nrt_ldf_group_key WHERE business_object_uid = @bo_uid
UNION ALL
SELECT 'ldf_group',              COUNT(*) FROM dbo.ldf_group         WHERE business_object_uid = @bo_uid
UNION ALL
SELECT 'nrt_ldf_data',           COUNT(*) FROM dbo.nrt_ldf_data      WHERE business_object_uid = @bo_uid;

GO

PRINT '';
PRINT '--------------------------------------------------------------------------------';
PRINT 'STEP 7: Cleanup -- remove every row this script created';
PRINT '         (key tables committed in the earlier SP per-step transactions)';
PRINT '--------------------------------------------------------------------------------';

DECLARE @bo_uid BIGINT = 29999999;

DELETE ld
FROM dbo.LDF_DATA ld
JOIN dbo.nrt_ldf_data_key k ON ld.ldf_data_key = k.d_ldf_data_key
WHERE k.business_object_uid = @bo_uid;

DELETE FROM dbo.nrt_ldf_data_key  WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.ldf_group         WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.nrt_ldf_group_key WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.nrt_ldf_data      WHERE business_object_uid = @bo_uid;

PRINT 'Cleanup complete.';
GO

PRINT '';
PRINT '--- end repro ---';
GO
