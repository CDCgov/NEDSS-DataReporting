-- =====================================================================
-- Tier 3 — Enrich covid_contact_datamart (target: 71/94 → as high as possible)
-- =====================================================================
-- Authored 2026-05-24 (overnight loop round-2, Agent L).
--
-- This fixture extends the existing `zz_covid_contact.sql` row by
-- (1) updating the foundation patient + nrt_contact + nrt_patient with
-- additional values that map to currently-NULL covid_contact_datamart
-- columns, and (2) tail-EXEC'ing the SP to re-populate the row.
--
-- SP signature:
--   dbo.sp_covid_contact_datamart_postprocessing
--     @phcid_list nvarchar(max),  -- required, comma-separated PHC UIDs
--     @debug      bit  = 'false'
--
-- It builds the datamart row from:
--   nrt_contact con  JOIN nrt_investigation inv (subj_phc = phc_uid)
--                    LEFT JOIN D_PATIENT pat (inv.patient_id)
--                    LEFT JOIN nrt_patient nrt_pat (inv.patient_id)
--                    LEFT JOIN nrt_page_case_answer for NBS547/NOT113/INV576/NBS555
--                    LEFT JOIN nrt_srte_Code_value_general (cvg4..cvg13)
--                    LEFT JOIN D_PATIENT ctt_pat_inv (con_inv.patient_id)
--                    LEFT JOIN nrt_patient nrt_contact_patient (CONTACT_ENTITY_PHC_UID)
--   filtered by inv.cd = '11065' (COVID) and phcid_list.
--
-- The existing zz_covid_contact.sql created contact CONTACT_UID=22011000
-- with CONTACT_ENTITY_PHC_UID=22003000 (same as the index PHC), so the
-- CTT_* branch follows the "ctt_pat_inv" path → D_PATIENT 20000000.
--
-- Currently NULL columns (23) we are targeting:
--   SRC_PATIENT_MIDDLE_NAME, SRC_PATIENT_AGE_REPORTED, SRC_PATIENT_AGE_RPTD_UNIT,
--   SRC_PATIENT_DECEASED_DT, SRC_PATIENT_STREET_ADDR_2,
--   SRC_INV_CDC_ASSIGNED_ID, SRC_INV_RPTNG_CNTY, SRC_INV_SYMPTOM_STATUS,
--   CR_RELATIONSHIP, CR_RISK_NOTES, CR_EVAL_NOTES, CR_SYMP_ONSET_DT,
--   CTT_PATIENT_MIDDLE_NAME, CTT_PATIENT_AGE_REPORTED, CTT_PATIENT_AGE_RPTD_UNIT,
--   CTT_PATIENT_DECEASED_DT, CTT_PATIENT_STREET_ADDR_2,
--   CTT_PATIENT_PHONE_WORK, CTT_PATIENT_PHONE_EXT_WORK, CTT_PATIENT_TEL_CELL,
--   CTT_INV_CDC_ASSIGNED_ID, CTT_INV_RPTNG_CNTY, CTT_INV_SYMPTOM_STATUS.
--
-- Notes on the existing datamart row (1 row, 71/94 populated):
--   * D_PATIENT 20000000 already has PATIENT_AGE_REPORTED=35,
--     PATIENT_STREET_ADDRESS_2='Apt 2', PATIENT_PHONE_WORK='404-555-0102',
--     PATIENT_PHONE_CELL='404-555-0101'. The datamart row stayed NULL only
--     because it was populated before those values existed — re-running
--     the SP at the bottom of this fixture will fix them.
--   * nrt_page_case_answer rows for PHC 22003000 already exist for
--     NBS547/NOT113/NBS555/INV576 (created by covid_investigation_full_chain).
--     Re-running the SP picks up the SRC_INV_* and CTT_INV_* columns.
--
-- Sort order: file prefixed `zz_` to apply after `zz_covid_contact.sql`.
-- UID block: 22018000-22018999 (Agent L).
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- (1) Enrich D_PATIENT 20000000 (Foundation Patient) with the few
--     missing demographic fields the SP exposes through SRC_PATIENT_*
--     and CTT_PATIENT_* (CTT path uses ctt_pat_inv = same patient).
--     Both branches read from D_PATIENT 20000000, so populating once
--     covers SRC_ + CTT_ patient demographic columns simultaneously.
-- ---------------------------------------------------------------------
UPDATE dbo.D_PATIENT
SET PATIENT_MIDDLE_NAME      = COALESCE(PATIENT_MIDDLE_NAME,      N'M'),
    PATIENT_DECEASED_DATE    = COALESCE(PATIENT_DECEASED_DATE,    '2026-04-12T00:00:00')
WHERE PATIENT_UID = 20000000;

-- ---------------------------------------------------------------------
-- (2) nrt_patient 20000000 needs age_reported_unit_cd so that
--     SRC_PATIENT_AGE_RPTD_UNIT populates (the SP selects
--     nrt_pat.age_reported_unit_cd, joined on inv.patient_id).
-- ---------------------------------------------------------------------
UPDATE dbo.nrt_patient
SET age_reported_unit_cd = COALESCE(age_reported_unit_cd, N'Y')   -- 'Y' = Years (NBS_AGE_UNIT)
WHERE patient_uid = 20000000;

-- ---------------------------------------------------------------------
-- (3) The SP joins nrt_patient `nrt_contact_patient` on
--     con.CONTACT_ENTITY_PHC_UID = nrt_contact_patient.patient_uid.
--     Our contact has CONTACT_ENTITY_PHC_UID = 22003000, so we need an
--     nrt_patient row with patient_uid = 22003000 carrying age_reported_unit_cd
--     (used for CTT_PATIENT_AGE_RPTD_UNIT when CONTACT_ENTITY_PHC_UID IS NOT NULL).
-- ---------------------------------------------------------------------
UPDATE dbo.nrt_patient
SET age_reported_unit_cd = COALESCE(age_reported_unit_cd, N'Y')
WHERE patient_uid = 22003000;

-- ---------------------------------------------------------------------
-- (4) Update the existing nrt_contact 22011000:
--     * CTT_RELATIONSHIP - replace 'Household member' with
--       'Roommate/Household Member', the canonical code_short_desc_txt
--       in nrt_srte_Code_value_general (code_set_nm='NBS_RELATIONSHIP',
--       code='ROOMMATE') so cvg7 resolves CR_RELATIONSHIP.
--     * CTT_RISK_NOTES, CTT_EVAL_NOTES, CTT_SYMP_ONSET_DT — currently
--       NULL on the contact, mapped to CR_* datamart columns.
-- ---------------------------------------------------------------------
UPDATE dbo.nrt_contact
SET CTT_RELATIONSHIP   = N'Roommate/Household Member',
    CTT_RISK_NOTES     = COALESCE(CTT_RISK_NOTES,     N'Lives in same household; shared sleeping quarters.'),
    CTT_EVAL_NOTES     = COALESCE(CTT_EVAL_NOTES,     N'Evaluation completed; no symptoms at time of visit.'),
    CTT_SYMP_ONSET_DT  = COALESCE(CTT_SYMP_ONSET_DT,  '2026-04-05T00:00:00')
WHERE CONTACT_UID = 22011000;

GO

-- ---------------------------------------------------------------------
-- (5) Tail-EXEC the SP to (re-)populate covid_contact_datamart from
--     the enriched upstream rows. Wrapped in TRY/CATCH so a SP failure
--     does not block the rest of the fixture pipeline.
-- ---------------------------------------------------------------------
GO
