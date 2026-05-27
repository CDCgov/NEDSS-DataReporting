USE RDB_MODERN;

-- Disable FK constraints during seed (some baseline tables have FKs back to dimensions).
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Use a private UID namespace (97xxxxxx) to avoid colliding with baseline data.
DECLARE @phc_uid bigint = 97000200;
DECLARE @ldf_uid_sub bigint = 97001977;  -- data_type=SUB, would trigger pre-fix early-RETURN
DECLARE @ldf_uid_cv  bigint = 97001978;  -- data_type=CV, should produce a dim row
DECLARE @ldf_uid_st  bigint = 97001979;  -- data_type=ST, should produce a dim row
DECLARE @condition_cd varchar(50) = N'97210';

-- Cleanup any prior remnants from this UID space
DELETE FROM dbo.LDF_DIMENSIONAL_DATA WHERE INVESTIGATION_UID = @phc_uid;
DELETE FROM dbo.LDF_DATAMART_COLUMN_REF WHERE LDF_UID IN (@ldf_uid_sub, @ldf_uid_cv, @ldf_uid_st);
DELETE FROM dbo.D_LDF_META_DATA WHERE ldf_uid IN (@ldf_uid_sub, @ldf_uid_cv, @ldf_uid_st);
DELETE FROM dbo.nrt_ldf_data WHERE business_object_uid = @phc_uid;
DELETE FROM dbo.nrt_odse_state_defined_field_metadata WHERE ldf_uid IN (@ldf_uid_sub, @ldf_uid_cv, @ldf_uid_st);
DELETE FROM dbo.nrt_investigation WHERE public_health_case_uid = @phc_uid;
DELETE FROM dbo.LDF_DATAMART_TABLE_REF WHERE condition_cd = @condition_cd;

-- LDF_DATAMART_TABLE_REF: declares that condition @condition_cd participates in LDF datamart processing
INSERT INTO dbo.LDF_DATAMART_TABLE_REF (CONDITION_CD, CONDITION_DESC, LDF_GROUP_ID, DATAMART_NAME, LINKED_FACT_TABLE, ENTITY_DESC)
VALUES (@condition_cd, N'Bug7 Test Condition', 999, N'LDF_BUG7_TEST', N'GENERIC_CASE', NULL);

-- nrt_investigation: minimal row so the SP's INNER JOIN on inv.cd matches LDF_DATAMART_TABLE_REF.condition_cd
INSERT INTO dbo.nrt_investigation (public_health_case_uid, cd)
VALUES (@phc_uid, @condition_cd);

-- nrt_odse_state_defined_field_metadata: 3 rows. One SUB (filtered out by data_type whitelist),
-- two valid (CV and ST). Pre-fix, the SUB row would cause the SP to early-RETURN for the whole batch.
INSERT INTO dbo.nrt_odse_state_defined_field_metadata
    (ldf_uid, active_ind, business_object_nm, code_set_nm, condition_cd, data_type, ldf_page_id, label_txt, class_cd, add_time, record_status_time, record_status_cd)
VALUES
    (@ldf_uid_sub, N'Y', N'PHC', NULL,  @condition_cd, N'SUB', N'9952', N'Bug7 SUB subform', N'PHC', '2026-05-17 00:00:00', '2026-05-17 00:00:00', N'ACTIVE'),
    (@ldf_uid_cv,  N'Y', N'PHC', N'YNU', @condition_cd, N'CV',  N'9952', N'Bug7 CV question',  N'PHC', '2026-05-17 00:00:00', '2026-05-17 00:00:00', N'ACTIVE'),
    (@ldf_uid_st,  N'Y', N'PHC', NULL,  @condition_cd, N'ST',  N'9952', N'Bug7 ST question',  N'PHC', '2026-05-17 00:00:00', '2026-05-17 00:00:00', N'ACTIVE');

-- nrt_ldf_data: actual ldf answer rows. ldf_page_id is NULL (the secondary bug condition - INNER JOIN dropped these).
INSERT INTO dbo.nrt_ldf_data
    (ldf_uid, business_object_uid, active_ind, ldf_meta_data_business_object_nm, ldf_field_data_business_object_nm, code_set_nm, condition_cd, data_type, ldf_page_id, ldf_value, label_txt)
VALUES
    (@ldf_uid_sub, @phc_uid, N'Y', N'PHC', N'PHC', NULL,  @condition_cd, N'SUB', NULL, N'Y', N'Bug7 SUB subform'),
    (@ldf_uid_cv,  @phc_uid, N'Y', N'PHC', N'PHC', N'YNU', @condition_cd, N'CV',  NULL, N'Y', N'Bug7 CV question'),
    (@ldf_uid_st,  @phc_uid, N'Y', N'PHC', N'PHC', NULL,  @condition_cd, N'ST',  NULL, N'42', N'Bug7 ST question');

EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Now invoke the SP. With the fix, this populates LDF_DIMENSIONAL_DATA with the CV and ST rows.
-- Without the fix, the SUB row causes early-RETURN and LDF_DIMENSIONAL_DATA is not updated.
DECLARE @ldf_id_list nvarchar(max) =
    CONCAT(CAST(@ldf_uid_sub AS varchar), N',', CAST(@ldf_uid_cv AS varchar), N',', CAST(@ldf_uid_st AS varchar));

EXEC dbo.sp_nrt_ldf_dimensional_data_postprocessing @ldf_id_list = @ldf_id_list, @debug = 0;
