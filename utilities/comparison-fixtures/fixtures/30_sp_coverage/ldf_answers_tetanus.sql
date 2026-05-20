-- =====================================================================
-- Tier 3 — LDF answer rows for Tetanus
-- =====================================================================
-- Goal: populate LDF_TETANUS, LDF_DIMENSIONAL_DATA, LDF_GROUP. Trigger
-- the LDF chain by authoring nrt_ldf_data rows that reference real LDF
-- metadata UIDs from nrt_odse_state_defined_field_metadata.
--
-- v1 chose Tetanus (condition_cd=10210) as the canonical LDF condition:
-- it has 87 LDF question definitions in baseline d_ldf_meta_data, and
-- sp_ldf_tetanus_datamart_postprocessing exists to populate LDF_TETANUS.
--
-- Approach: pick 5 representative LDF UIDs from the Tetanus metadata
-- and author nrt_ldf_data answer rows attached to the Tetanus
-- Investigation (UID 22000010 — but wait, that's TB; the Tetanus
-- variant doesn't exist yet). Add a Tetanus Investigation variant in
-- this fixture too, since multi_condition_investigations.sql didn't
-- include Tetanus.
--
-- UIDs:
--   22000200 — Tetanus Investigation (condition_cd 10210)
--   nrt_ldf_data uses ldf_uid (from baseline metadata) +
--     business_object_uid (the Investigation UID).
-- =====================================================================

USE [RDB_MODERN];

-- Add Tetanus Investigation variant
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_time], [last_chg_time], [investigation_status_cd])
VALUES
    (22000200, N'CAS22000200GA01', N'F', N'I',
     N'130001', N'ACTIVE', N'EVN', N'CASE',
     N'C', N'10210', N'Tetanus', N'VAC',
     N'INV_FORM_GEN', NULL,
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'O');

-- RTR bug #5b: see multi_condition_investigations.sql for rationale.
UPDATE dbo.nrt_investigation
   SET patient_id = 20000000
 WHERE public_health_case_uid = 22000200;

EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22000200', @debug = 0;

-- Author nrt_ldf_data answer rows for the first 5 Tetanus LDFs.
-- Pulls ldf_uid + ldf_meta_data fields from nrt_odse_state_defined_field_metadata
-- so we don't have to hard-code UIDs (the baseline LDF UIDs may shift).
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
    22000200 AS business_object_uid,    -- Tetanus Investigation
    'PHC' AS ldf_field_data_business_object_nm,
    'Y' AS active_ind,
    md.business_object_nm,
    md.condition_cd,
    md.label_txt,
    md.data_type,
    md.code_set_nm,
    'Y' AS ldf_value,                    -- generic positive answer
    md.data_type AS ldf_column_type,
    'ACTIVE' AS record_status_cd,
    '2026-04-01T00:00:00' AS ldf_data_field_add_time,
    '2026-04-01T00:00:00' AS ldf_data_last_chg_time,
    'ACTIVE' AS metadata_record_status_cd,  -- LDF_DATA.record_status_cd is varchar(8); 'LDF_PROCESSED' (13) would truncate. RTR bug.
    '2026-04-01T00:00:00' AS metadata_record_status_time,
    '2026-04-01T00:00:00' AS ldf_meta_data_add_time
FROM dbo.nrt_odse_state_defined_field_metadata md
WHERE md.business_object_nm = 'PHC'
  AND md.condition_cd = '10210'
ORDER BY md.ldf_uid;

-- Run the LDF chain
DECLARE @ldf_uids nvarchar(max);
SELECT @ldf_uids = STRING_AGG(CAST(ldf_uid AS varchar), ',')
FROM dbo.nrt_ldf_data
WHERE business_object_uid = 22000200;

EXEC dbo.sp_nrt_ldf_postprocessing @ldf_uid_list = @ldf_uids, @debug = 0;
EXEC dbo.sp_nrt_ldf_dimensional_data_postprocessing @ldf_id_list = @ldf_uids, @debug = 0;
EXEC dbo.sp_ldf_tetanus_datamart_postprocessing @phc_id_list = N'22000200', @debug = 0;
