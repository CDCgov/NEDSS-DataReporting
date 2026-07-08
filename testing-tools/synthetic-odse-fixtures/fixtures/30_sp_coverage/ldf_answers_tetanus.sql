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

-- Add Tetanus Investigation variant.
-- patient_id = 20000000 (foundation Patient) so the downstream Datamart
-- chain doesn't drop the row via the sentinel-key cascade —
-- see fixtures/10_subjects/investigation.sql for the convention.


-- Author nrt_ldf_data answer rows for the first 5 Tetanus LDFs.
-- Pulls ldf_uid + ldf_meta_data fields from nrt_odse_state_defined_field_metadata
-- so we don't have to hard-code UIDs (the baseline LDF UIDs may shift).

-- Run the LDF chain
DECLARE @ldf_uids nvarchar(max);
SELECT @ldf_uids = STRING_AGG(CAST(ldf_uid AS varchar), ',')
FROM dbo.nrt_ldf_data
WHERE business_object_uid = 22000200;

