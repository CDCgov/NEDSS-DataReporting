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
INSERT INTO [dbo].[nrt_contact]
    (CONTACT_UID, SUBJECT_ENTITY_PHC_UID, CONTACT_ENTITY_PHC_UID,
     CONTACT_ENTITY_UID, RECORD_STATUS_CD,
     ADD_TIME, ADD_USER_ID,
     CTT_STATUS, CTT_STATUS_CODE,
     CTT_PRIORITY, CTT_RELATIONSHIP, CTT_HEALTH_STATUS,
     CTT_DISPOSITION, CTT_DISPO_DT,
     CTT_NAMED_ON_DT, CTT_JURISDICTION_NM,
     CTT_INV_ASSIGNED_DT, CTT_EVAL_COMPLETED, CTT_EVAL_DT,
     CTT_SHARED_IND, CTT_RISK_IND, CTT_SYMP_IND)
VALUES
    (22011000, 22003000, 22003000,
     20000000, N'ACTIVE',
     '2026-04-01T00:00:00', 10009282,
     N'Active', N'A',
     N'HIGH', N'Household member', N'Asymptomatic',
     N'Pending evaluation', '2026-04-15T00:00:00',
     '2026-04-02T00:00:00', N'Fulton County',
     '2026-04-03T00:00:00', N'Y', '2026-04-10T00:00:00',
     N'Y', N'Y', N'N');

-- Add a few nrt_contact_answer rows so the SP's exposure-type/site
-- joins populate.
-- SP uses answer_code for CTT_EXPOSURE_TYPE, answer_val for the rest.
INSERT INTO [dbo].[nrt_contact_answer]
    (contact_uid, rdb_column_nm, answer_val, answer_code)
VALUES
    (22011000, N'CTT_EXPOSURE_TYPE',      N'Direct contact', N'DC'),
    (22011000, N'CTT_EXPOSURE_SITE_TYPE', N'Household',      NULL),
    (22011000, N'CTT_FIRST_EXPOSURE_DT',  N'2026-03-28',     NULL),
    (22011000, N'CTT_LAST_EXPOSURE_DT',   N'2026-04-01',     NULL);
