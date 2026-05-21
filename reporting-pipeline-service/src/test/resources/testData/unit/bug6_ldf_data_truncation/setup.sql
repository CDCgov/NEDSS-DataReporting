USE RDB_MODERN;

-- Disable FK constraints during seed (some baseline tables have FKs back to dimensions).
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Use a private UID namespace (96xxxxxx) to avoid colliding with baseline data
-- and other bug-fix tests (bug7 uses 97xxxxxx).
DECLARE @bo_uid bigint = 96000600;
DECLARE @ldf_uid bigint = 96001976;
DECLARE @condition_cd varchar(50) = N'96210';

-- Cleanup any prior remnants from this UID space
DELETE ld
FROM dbo.LDF_DATA ld
JOIN dbo.nrt_ldf_data_key k ON ld.ldf_data_key = k.d_ldf_data_key
WHERE k.business_object_uid = @bo_uid;

DELETE FROM dbo.nrt_ldf_data_key  WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.ldf_group         WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.nrt_ldf_group_key WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.nrt_ldf_data      WHERE business_object_uid = @bo_uid;
DELETE FROM dbo.nrt_odse_state_defined_field_metadata WHERE ldf_uid = @ldf_uid;

-- Metadata row: SP inner joins on ldf_uid and filters on active_ind <> 'N'.
-- record_status_cd here holds the canonical 13-char 'LDF_PROCESSED' value
-- (this is what the pre-fix SP incorrectly read from nrt_ldf_data and
-- forwarded into LDF_DATA.RECORD_STATUS_CD varchar(8)).
INSERT INTO dbo.nrt_odse_state_defined_field_metadata
    (ldf_uid, active_ind, business_object_nm, code_set_nm, condition_cd, data_type,
     ldf_page_id, label_txt, class_cd, add_time, record_status_time, record_status_cd)
VALUES
    (@ldf_uid, N'Y', N'PHC', N'YNU', @condition_cd, N'CV', N'9952',
     N'Bug6 LDF answer', N'PHC',
     '2026-05-17 00:00:00', '2026-05-17 00:00:00', N'LDF_PROCESSED');

-- nrt_ldf_data: the answer row that flows through the SP.
-- record_status_cd='ACTIVE' (8-char-safe, passes LDF_DATA.RECORD_STATUS_CD
-- CHECK constraint; this is the column the FIXED SP must read).
-- metadata_record_status_cd='LDF_PROCESSED' (the 13-char value the BUGGY
-- SP would have read, causing Msg 2628 truncation).
INSERT INTO dbo.nrt_ldf_data
    (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
     active_ind, ldf_meta_data_business_object_nm,
     condition_cd, label_txt, data_type, code_set_nm,
     ldf_value, ldf_column_type,
     record_status_cd,
     metadata_record_status_cd,
     ldf_data_field_add_time, ldf_data_last_chg_time,
     metadata_record_status_time, ldf_meta_data_add_time)
VALUES
    (@ldf_uid, @bo_uid, N'PHC', N'Y', N'PHC',
     @condition_cd, N'Bug6 LDF answer', N'CV', N'YNU',
     N'Y', N'CV',
     N'ACTIVE',
     N'LDF_PROCESSED',
     '2026-05-17 00:00:00', '2026-05-17 00:00:00',
     '2026-05-17 00:00:00', '2026-05-17 00:00:00');

EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Invoke the SP. With the fix, LDF_DATA receives one row with
-- RECORD_STATUS_CD='ACTIVE'. Pre-fix, the SP's INSERT INTO LDF_DATA
-- aborted with Msg 2628 (varchar(8) truncation) and no row was inserted.
DECLARE @ldf_uid_list nvarchar(max) = CAST(@ldf_uid AS varchar);
EXEC dbo.sp_nrt_ldf_postprocessing @ldf_uid_list = @ldf_uid_list, @debug = 0;
