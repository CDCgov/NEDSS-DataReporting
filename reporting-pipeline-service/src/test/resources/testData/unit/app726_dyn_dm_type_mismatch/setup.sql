-- APP-726: sp_dyn_dm_createdm_postprocessing should handle non-decimal mismatched types
-- by dropping/re-adding target columns with the source type metadata before UPDATE.
-- This fixture forces mismatches for float, datetime2, datetimeoffset, time,
-- nvarchar, and varbinary and verifies the run completes without Operand type clash.

-- Base context and test identifiers.
-- Uses a fixed batch/datamart name so all generated tmp_DynDm_* objects are deterministic.
USE RDB_MODERN;

DECLARE @batch_id BIGINT = 726001;
DECLARE @datamart_name VARCHAR(100) = 'APP726';
DECLARE @suffix VARCHAR(100) = @datamart_name + '_' + CAST(@batch_id AS VARCHAR(50));
DECLARE @sql NVARCHAR(MAX);

-- Clear prior job log rows for this package_name to isolate this run's assertions.
DELETE FROM dbo.job_flow_log
WHERE package_name = 'sp_dyn_dm_createdm_postprocessing: APP726';

-- Recreate the target datamart table with intentionally WRONG types.
-- The procedure under test should detect and correct these mismatches.
IF OBJECT_ID('dbo.DM_INV_APP726', 'U') IS NOT NULL
    DROP TABLE dbo.DM_INV_APP726;

CREATE TABLE dbo.DM_INV_APP726 (
    INVESTIGATION_KEY BIGINT NOT NULL,
    SRC_FLOAT DATE NULL,
    SRC_DT2 FLOAT NULL,
    SRC_DTO DATE NULL,
    SRC_TM DATETIME NULL,
    SRC_NVC VARCHAR(5) NULL,
    SRC_BIN VARCHAR(10) NULL
);

-- Seed one row in the target table. The values themselves are less important than the type mismatch.
INSERT INTO dbo.DM_INV_APP726
(
    INVESTIGATION_KEY,
    SRC_FLOAT,
    SRC_DT2,
    SRC_DTO,
    SRC_TM,
    SRC_NVC,
    SRC_BIN
)
VALUES
(
    1,
    '2026-01-01',
    1.0,
    '2026-01-01',
    '2026-01-01T00:00:00',
    'old',
    'old'
);

-- Create all tmp_DynDm_* staging tables expected by the procedure.
-- Only two tables need test data, but the procedure references this broader set by naming convention.
DECLARE @tables TABLE (name SYSNAME NOT NULL);
INSERT INTO @tables(name)
VALUES
('tmp_DynDm_INV_SUMM_DATAMART_' + @suffix),
('tmp_DynDm_Investigation_Data_' + @suffix),
('tmp_DynDm_Patient_Data_' + @suffix),
('tmp_DynDm_Case_Management_Data_' + @suffix),
('tmp_DynDm_D_INV_Administrative_' + @suffix),
('tmp_DynDm_D_INV_CLINICAL_' + @suffix),
('tmp_DynDm_D_INV_COMPLICATION_' + @suffix),
('tmp_DynDm_D_INV_CONTACT_' + @suffix),
('tmp_DynDm_D_INV_DEATH_' + @suffix),
('tmp_DynDm_D_INV_EPIDEMIOLOGY_' + @suffix),
('tmp_DynDm_D_INV_HIV_' + @suffix),
('tmp_DynDm_D_INV_PATIENT_OBS_' + @suffix),
('tmp_DynDm_D_INV_ISOLATE_TRACKING_' + @suffix),
('tmp_DynDm_D_INV_LAB_FINDING_' + @suffix),
('tmp_DynDm_D_INV_MEDICAL_HISTORY_' + @suffix),
('tmp_DynDm_D_INV_MOTHER_' + @suffix),
('tmp_DynDm_D_INV_OTHER_' + @suffix),
('tmp_DynDm_D_INV_PREGNANCY_BIRTH_' + @suffix),
('tmp_DynDm_D_INV_RESIDENCY_' + @suffix),
('tmp_DynDm_D_INV_RISK_FACTOR_' + @suffix),
('tmp_DynDm_D_INV_SOCIAL_HISTORY_' + @suffix),
('tmp_DynDm_D_INV_SYMPTOM_' + @suffix),
('tmp_DynDm_D_INV_TREATMENT_' + @suffix),
('tmp_DynDm_D_INV_TRAVEL_' + @suffix),
('tmp_DynDm_D_INV_UNDER_CONDITION_' + @suffix),
('tmp_DynDm_D_INV_VACCINATION_' + @suffix),
('tmp_DynDm_D_INV_STD_' + @suffix),
('tmp_DynDm_Organization_' + @suffix),
('tmp_DynDm_PROVIDER_' + @suffix),
('tmp_DynDm_INVESTIGATION_REPEAT_VARCHAR_' + @suffix),
('tmp_DynDm_REPEAT_BLOCK_VARCHAR_ALL_' + @suffix),
('tmp_DynDm_INVESTIGATION_REPEAT_DATE_' + @suffix),
('tmp_DynDm_REPEAT_BLOCK_DATE_ALL_' + @suffix),
('tmp_DynDm_INVESTIGATION_REPEAT_NUMERIC_' + @suffix),
('tmp_DynDm_REPEAT_BLOCK_NUMERIC_ALL_' + @suffix);

DECLARE @name SYSNAME;
DECLARE table_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name FROM @tables;

-- For each required staging table, drop any prior copy and recreate with INVESTIGATION_KEY.
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
        IF OBJECT_ID(''dbo.' + @name + ''', ''U'') IS NOT NULL
            DROP TABLE dbo.' + QUOTENAME(@name) + N';
        CREATE TABLE dbo.' + QUOTENAME(@name) + N' (
            INVESTIGATION_KEY BIGINT NOT NULL
        );';
    EXEC sp_executesql @sql;

    FETCH NEXT FROM table_cursor INTO @name;
END;
CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Add source columns to Investigation staging with the CORRECT source-side types.
-- The procedure should align DM_INV_APP726 column definitions to these types.
SET @sql = N'
ALTER TABLE dbo.' + QUOTENAME('tmp_DynDm_Investigation_Data_' + @suffix) + N'
ADD
    SRC_FLOAT FLOAT(53) NULL,
    SRC_DT2 DATETIME2(3) NULL,
    SRC_DTO DATETIMEOFFSET(2) NULL,
    SRC_TM TIME(4) NULL,
    SRC_NVC NVARCHAR(40) NULL,
    SRC_BIN VARBINARY(12) NULL;';
EXEC sp_executesql @sql;

-- Seed the minimum staging rows used by postprocessing joins/updates.
SET @sql = N'
INSERT INTO dbo.' + QUOTENAME('tmp_DynDm_INV_SUMM_DATAMART_' + @suffix) + N' (INVESTIGATION_KEY)
VALUES (1);';
EXEC sp_executesql @sql;

-- Insert one source row with representative values across all mismatched data types.
SET @sql = N'
INSERT INTO dbo.' + QUOTENAME('tmp_DynDm_Investigation_Data_' + @suffix) + N'
(
    INVESTIGATION_KEY,
    SRC_FLOAT,
    SRC_DT2,
    SRC_DTO,
    SRC_TM,
    SRC_NVC,
    SRC_BIN
)
VALUES
(
    1,
    123.5,
    ''2026-08-11T12:34:56.789'',
    ''2026-08-11T12:34:56.78+00:00'',
    ''12:34:56.1234'',
    N''Widened text value'',
    0x01020304
);';
EXEC sp_executesql @sql;

-- Execute procedure under test.
-- Success criteria are validated in query.sql / expected.json (job_flow_log first, schema second).
EXEC dbo.sp_dyn_dm_createdm_postprocessing
    @batch_id = @batch_id,
    @DATAMART_NAME = @datamart_name,
    @debug = 0;
