-- =====================================================================
-- Tier 3 — Enrich the v2 nrt_vaccination row
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #9).
--
-- Goal: push covid_vaccination_datamart 10/60 -> partial+.
-- sp_covid_vaccination_datamart_postprocessing reads NRT_VACCINATION
-- by patient_uid (no COVID-specific filter). The existing v2
-- vaccination row (20110010, patient_uid=20000000) is thin —
-- broaden its populated columns.
-- =====================================================================

USE [RDB_MODERN];
GO

UPDATE [dbo].[nrt_vaccination]
   SET age_at_vaccination          = COALESCE(age_at_vaccination,           N'45'),
       age_at_vaccination_unit     = COALESCE(age_at_vaccination_unit,      N'Y'),
       vaccine_administered_date   = COALESCE(vaccine_administered_date,    '2026-02-15T00:00:00'),
       vaccine_dose_nbr            = COALESCE(vaccine_dose_nbr,             N'3'),
       vaccination_administered_nm = COALESCE(vaccination_administered_nm,  N'COVID-19 vaccine, mRNA, bivalent'),
       vaccination_anatomical_site = COALESCE(vaccination_anatomical_site,  N'Left deltoid'),
       vaccine_expiration_dt       = COALESCE(vaccine_expiration_dt,        '2027-06-30T00:00:00'),
       vaccine_info_source         = COALESCE(vaccine_info_source,          N'Vaccine information statement'),
       vaccine_lot_number_txt      = COALESCE(vaccine_lot_number_txt,       N'LOT-COV-MRNA-2024-12-A'),
       vaccine_manufacturer_nm     = COALESCE(vaccine_manufacturer_nm,      N'Pfizer-BioNTech'),
       electronic_ind              = COALESCE(electronic_ind,               N'Y'),
       phc_uid                     = COALESCE(phc_uid,                      22003000),
       status_time                 = COALESCE(status_time,                  '2026-02-15T00:00:00'),
       prog_area_cd                = COALESCE(prog_area_cd,                 N'COV'),
       jurisdiction_cd             = COALESCE(jurisdiction_cd,              N'130001'),
       program_jurisdiction_oid    = COALESCE(program_jurisdiction_oid,     22003000),
       material_cd                 = COALESCE(material_cd,                  N'208'),
       local_id                    = COALESCE(local_id,                     N'VAC20110010LOCAL'),
       provider_uid                = COALESCE(provider_uid,                 20000010),
       organization_uid            = COALESCE(organization_uid,             20000020)
 WHERE vaccination_uid = 20110010;
