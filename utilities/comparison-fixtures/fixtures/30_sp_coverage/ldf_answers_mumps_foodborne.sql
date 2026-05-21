-- =====================================================================
-- Tier 3 — LDF answers for Mumps + Foodborne conditions
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #2).
--
-- Goal: populate LDF_MUMPS and LDF_FOODBORNE (currently both 0/7) by
-- replicating the Tetanus template (`ldf_answers_tetanus.sql`) for two
-- more conditions whose nrt_odse_state_defined_field_metadata tables
-- have entries.
--
-- Per discovery query in loop iter 2:
--   condition 10180 (Mumps):         37 PHC LDF metadata rows
--   condition 10470 (Foodborne — Salmonellosis): 117 PHC LDF metadata rows
--   LDF_DATAMART_TABLE_REF confirms both are mapped to their datamart.
--
-- NOT in scope for this iteration:
--   LDF_BMIRD (0 metadata; cannot populate without seeding metadata)
--   LDF_HEPATITIS (0 metadata; same)
--   LDF_VACCINE_PREVENT_DISEASES (0 metadata; already 8/8 via another path)
--
-- UID layout (within block 22008000-22008999):
--   22000030 — existing Mumps stub (NOT modified; LDF rows attach to it)
--   22008000 — new Foodborne Investigation (Salmonellosis 10470)
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- Foodborne Investigation variant (Salmonellosis, condition_cd=10470).
-- The existing multi_condition_investigations.sql stub list does not
-- include Foodborne, so we create one. INV_FORM_GEN is the generic
-- investigation form; the LDF datamart SP doesn't filter on form_cd,
-- only on condition_cd → LDF_DATAMART_TABLE_REF mapping.
-- patient_id = 20000000 (foundation Patient) for the bug-5b convention.
-- =====================================================================
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_time], [last_chg_time], [investigation_status_cd])
VALUES
    (22008000, 20000000, N'CAS22008000GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10470', N'Salmonellosis', N'FOOD',
     N'INV_FORM_GEN', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O');

EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22008000', @debug = 0;

-- =====================================================================
-- LDF answer rows for Mumps (PHC 22000030, condition 10180).
-- Reuse the Tetanus pattern: SELECT TOP 5 from metadata, blanket 'Y'
-- answer. record_status_cd='ACTIVE' (varchar(8); 'LDF_PROCESSED' would
-- truncate — known RTR bug, see ldf_answers_tetanus.sql comment).
-- =====================================================================
INSERT INTO [dbo].[nrt_ldf_data]
    (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
     active_ind, ldf_meta_data_business_object_nm,
     condition_cd, label_txt, data_type, code_set_nm,
     ldf_value, ldf_column_type, record_status_cd,
     ldf_data_field_add_time, ldf_data_last_chg_time,
     metadata_record_status_cd, metadata_record_status_time,
     ldf_meta_data_add_time)
SELECT TOP 5
    md.ldf_uid,
    22000030 AS business_object_uid,    -- Mumps stub PHC
    'PHC' AS ldf_field_data_business_object_nm,
    'Y' AS active_ind,
    md.business_object_nm,
    md.condition_cd,
    md.label_txt,
    md.data_type,
    md.code_set_nm,
    'Y' AS ldf_value,
    md.data_type AS ldf_column_type,
    'ACTIVE' AS record_status_cd,
    '2026-04-01T00:00:00' AS ldf_data_field_add_time,
    '2026-04-01T00:00:00' AS ldf_data_last_chg_time,
    'ACTIVE' AS metadata_record_status_cd,
    '2026-04-01T00:00:00' AS metadata_record_status_time,
    '2026-04-01T00:00:00' AS ldf_meta_data_add_time
FROM dbo.nrt_odse_state_defined_field_metadata md
WHERE md.business_object_nm = 'PHC'
  AND md.condition_cd = '10180'
ORDER BY md.ldf_uid;

-- =====================================================================
-- LDF answer rows for Foodborne (PHC 22008000, condition 10470).
-- =====================================================================
INSERT INTO [dbo].[nrt_ldf_data]
    (ldf_uid, business_object_uid, ldf_field_data_business_object_nm,
     active_ind, ldf_meta_data_business_object_nm,
     condition_cd, label_txt, data_type, code_set_nm,
     ldf_value, ldf_column_type, record_status_cd,
     ldf_data_field_add_time, ldf_data_last_chg_time,
     metadata_record_status_cd, metadata_record_status_time,
     ldf_meta_data_add_time)
SELECT TOP 5
    md.ldf_uid,
    22008000 AS business_object_uid,
    'PHC' AS ldf_field_data_business_object_nm,
    'Y' AS active_ind,
    md.business_object_nm,
    md.condition_cd,
    md.label_txt,
    md.data_type,
    md.code_set_nm,
    'Y' AS ldf_value,
    md.data_type AS ldf_column_type,
    'ACTIVE' AS record_status_cd,
    '2026-04-01T00:00:00' AS ldf_data_field_add_time,
    '2026-04-01T00:00:00' AS ldf_data_last_chg_time,
    'ACTIVE' AS metadata_record_status_cd,
    '2026-04-01T00:00:00' AS metadata_record_status_time,
    '2026-04-01T00:00:00' AS ldf_meta_data_add_time
FROM dbo.nrt_odse_state_defined_field_metadata md
WHERE md.business_object_nm = 'PHC'
  AND md.condition_cd = '10470'
ORDER BY md.ldf_uid;

-- =====================================================================
-- Run the LDF chain for both conditions' answers.
-- =====================================================================
DECLARE @ldf_uids nvarchar(max);
SELECT @ldf_uids = STRING_AGG(CAST(ldf_uid AS varchar), ',')
FROM dbo.nrt_ldf_data
WHERE business_object_uid IN (22000030, 22008000);

EXEC dbo.sp_nrt_ldf_postprocessing @ldf_uid_list = @ldf_uids, @debug = 0;
EXEC dbo.sp_nrt_ldf_dimensional_data_postprocessing @ldf_id_list = @ldf_uids, @debug = 0;

-- The per-condition LDF datamart SPs read LDF_DIMENSIONAL_DATA filtered
-- by PHC_CD → LDF_DATAMART_TABLE_REF.condition_cd. We do NOT tail-EXEC
-- them here — Step 9 of merge_and_verify.sh owns them against $PHC_UIDS.
-- Adding 22008000 to PHC_UIDS in this commit so Step 9 processes it.
