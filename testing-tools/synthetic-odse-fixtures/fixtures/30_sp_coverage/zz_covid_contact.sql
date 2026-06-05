-- =====================================================================
-- Tier 3 — COVID contact for covid_contact_datamart
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #8).
--
-- Goal: populate COVID_CONTACT_DATAMART (currently 0/94).
--
-- sp_covid_contact_datamart_postprocessing reads nrt_contact rows
-- joined to nrt_investigation on SUBJECT_ENTITY_PHC_UID = public_health_case_uid
-- and filters on inv.cd = '11065' (COVID-19 condition). The existing
-- 2 nrt_contact rows from Tier 1 point at the Hep A foundation PHC
-- (20000100, condition 10110), so they don't match the COVID filter.
--
-- Add 1 contact row pointing at the COVID Investigation PHC 22003000
-- (condition 11065). UID 22011000 (allocated within the Tier 3 block).
--
-- Sort order: file prefixed `zz_` to apply after Phase-2 fixtures that
-- create PHC 22003000 (covid_investigation_full_chain.sql).
-- =====================================================================

USE [RDB_MODERN];
GO

-- Insert a contact pointing at the COVID Investigation.
-- Note: CTT_EXPOSURE_TYPE etc. are not nrt_contact columns; the SP
-- pulls them from nrt_contact_answer instead. Keeping the INSERT to
-- columns that actually exist on nrt_contact.

-- Add a few nrt_contact_answer rows so the SP's exposure-type/site
-- joins populate.
-- SP uses answer_code for CTT_EXPOSURE_TYPE, answer_val for the rest.
