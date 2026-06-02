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


-- =====================================================================
-- LDF answer rows for Mumps (PHC 22000030, condition 10180).
-- Reuse the Tetanus pattern: SELECT TOP 5 from metadata, blanket 'Y'
-- answer. record_status_cd='ACTIVE' (varchar(8); 'LDF_PROCESSED' would
-- truncate — known RTR bug, see ldf_answers_tetanus.sql comment).
-- =====================================================================

-- =====================================================================
-- LDF answer rows for Foodborne (PHC 22008000, condition 10470).
-- =====================================================================

-- =====================================================================
-- Run the LDF chain for both conditions' answers.
-- =====================================================================
DECLARE @ldf_uids nvarchar(max);
SELECT @ldf_uids = STRING_AGG(CAST(ldf_uid AS varchar), ',')
FROM dbo.nrt_ldf_data
WHERE business_object_uid IN (22000030, 22008000);


-- The per-condition LDF datamart SPs read LDF_DIMENSIONAL_DATA filtered
-- by PHC_CD → LDF_DATAMART_TABLE_REF.condition_cd. We do NOT tail-EXEC
-- them here — Step 9 of merge_and_verify.sh owns them against $PHC_UIDS.
-- Adding 22008000 to PHC_UIDS in this commit so Step 9 processes it.
