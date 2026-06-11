-- ============================================================
-- sp_nrt_provider_postprocessing / sp_provider_dim_columns_update_to_datamart
-- Unit tests for sp_nrt_provider_postprocessing
--     Provider 1: PROVIDER_QUICK_CODE propagates correctly to
--                 AGGREGATE_REPORT_DATAMART when only
--                 std_hiv_datamart_update is triggered (bug fix)
-- ============================================================

USE [RDB_Modern];

-- ------------------------------------------------------------
-- UIDs / keys
-- ------------------------------------------------------------

-- Provider 1
DECLARE @provider_uid_1 BIGINT = 90100001;
DECLARE @provider_key_1 BIGINT;

-- ------------------------------------------------------------
-- nrt_provider_key
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_provider_key (provider_uid)
VALUES (@provider_uid_1);
SET @provider_key_1 = SCOPE_IDENTITY();

-- ------------------------------------------------------------
-- d_provider — stale quick code; all other comparison-checked
-- fields NULL
-- ------------------------------------------------------------
INSERT INTO dbo.D_PROVIDER (
    PROVIDER_KEY,
    PROVIDER_UID,
    PROVIDER_RECORD_STATUS,
    PROVIDER_QUICK_CODE
)
VALUES (
           @provider_key_1,
           @provider_uid_1,
           'ACTIVE',
           'OLD_QC'          -- stale — will differ from nrt_provider
       );

-- ------------------------------------------------------------
-- nrt_provider — updated quick code only; all other
-- comparison-checked fields NULL
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_provider (
    provider_uid,
    record_status,
    local_id,
    quick_code
)
VALUES (
           @provider_uid_1,
           'ACTIVE',
           'PRV' + CAST(@provider_uid_1 AS VARCHAR),
           'NEW_QC'          -- new value triggers std_hiv_datamart_update = 1
       );

-- ------------------------------------------------------------
-- AGGREGATE_REPORT_DATAMART — stale quick code for provider 1
-- ------------------------------------------------------------
INSERT INTO dbo.AGGREGATE_REPORT_DATAMART (
    PROVIDER_KEY,
    PROVIDER_UID,
    PROVIDER_QUICK_CODE
)
VALUES (
           @provider_key_1,
           @provider_uid_1,
           'OLD_QC'          -- stale — SP should replace with 'NEW_QC'
       );

-- ------------------------------------------------------------
-- Execute SP — writes to AGGREGATE_REPORT_DATAMART
-- ------------------------------------------------------------
EXEC dbo.sp_nrt_provider_postprocessing
    @id_list = '90100001';