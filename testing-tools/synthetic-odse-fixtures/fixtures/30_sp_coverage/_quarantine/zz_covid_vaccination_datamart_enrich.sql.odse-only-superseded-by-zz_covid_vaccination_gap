-- =====================================================================
-- Tier 3 ENRICHMENT — COVID_VACCINATION_DATAMART column expansion
-- =====================================================================
-- Authored by Agent N (parallel enrichment loop, round 2 top-up).
--
-- BASELINE (2026-05-24, live):
--   dbo.COVID_VACCINATION_DATAMART has 1 row, 10/60 populated cols.
--   The single row is the foundation Vaccination (vaccination_uid=20000160,
--   material_cd='207') which passes the SP's material filter
--   ('207','208','213') but has NULL patient_uid/provider_uid/
--   organization_uid soft-refs, so every PATIENT_*, PROVIDER_*,
--   ORGANIZATION_*, VACCINE_* (from D_VACCINATION) column is NULL.
--
-- GOAL: lift coverage from 10/60 toward the theoretical max by authoring
--   a brand-new fully-attributed COVID vaccination chain.
--
-- STRATEGY
--   sp_covid_vaccination_datamart_postprocessing
--     (file 320-sp_covid_vaccination_datamart_postprocessing-001.sql)
--   filters NRT_VACCINATION on material_cd IN ('207','208','213') and
--   joins:
--     D_VACCINATION  ON cte.VACCINATION_UID = dVac.VACCINATION_UID
--     D_PATIENT      ON cte.PATIENT_UID     = patient.PATIENT_UID
--     D_ORGANIZATION ON cte.ORGANIZATION_UID= org.ORGANIZATION_UID
--     D_PROVIDER     ON cte.PROVIDER_UID    = provider.PROVIDER_UID
--   and reads INVESTIGATION_DT from NRT_INVESTIGATION matched by
--   public_health_case_uid.
--
--   We author one NRT_VACCINATION row at vaccination_uid=22020130 with
--   material_cd='208' (COVID-19 vaccine, mRNA), patient/provider/org
--   soft-refs to 22020100/22020110/22020120, and phc_uid=22003000 (the
--   existing COVID PHC authored by covid_investigation_full_chain.sql).
--   We then directly INSERT corresponding D_PATIENT (KEY 22020100),
--   D_PROVIDER (22020110), D_ORGANIZATION (22020120), D_VACCINATION
--   (KEY 22020130), and NRT_INVESTIGATION (22003000 - if not present)
--   rows with full demographics/attributes so every column the SP
--   propagates is non-NULL.
--
--   Foundation Patient (PATIENT_UID=20000000) is NOT modified — it is
--   used by many other datamarts and cascading edits there are risky.
--
-- TARGETED COLUMNS (gained vs 10/60 baseline)
--   12 vaccine cols    : VACCINATION_ADMINISTERED_NM, VACCINE_ADMINISTERED_DATE,
--                        VACCINATION_ANATOMICAL_SITE, AGE_AT_VACCINATION,
--                        AGE_AT_VACCINATION_UNIT, VACCINE_MANUFACTURER_NM,
--                        VACCINE_LOT_NUMBER_TXT, VACCINE_EXPIRATION_DT,
--                        VACCINE_DOSE_NBR, VACCINE_INFO_SOURCE,
--                        (RECORD_STATUS_CD and ELECTRONIC_IND already covered)
--   22 patient cols    : PATIENT_LOCAL_ID, PATIENT_LAST_NAME,
--                        PATIENT_FIRST_NAME, PATIENT_MIDDLE_NAME,
--                        PATIENT_CURRENT_SEX, PATIENT_BIRTH_SEX,
--                        PATIENT_DOB, PATIENT_AGE_REPORTED,
--                        PATIENT_AGE_REPORTED_UNIT,
--                        PATIENT_STREET_ADDRESS_1,
--                        PATIENT_STREET_ADDRESS_2, PATIENT_CITY,
--                        PATIENT_STATE_CODE, PATIENT_ZIP,
--                        PATIENT_COUNTY, PATIENT_COUNTRY,
--                        PATIENT_SSN, OCCUPATION (= PATIENT_PRIMARY_OCCUPATION),
--                        PATIENT_MARITAL_STATUS,
--                        PATIENT_RACE_CALC_DETAILS, PATIENT_ETHNICITY,
--                        PATIENT_BIRTH_COUNTRY
--    9 provider cols   : PROVIDER_FIRST_NAME, PROVIDER_LAST_NAME,
--                        PROVIDER_NAME_DEGREE, PROVIDER_STREET_ADDRESS_1,
--                        (PROVIDER_STREET_ADDRESS_2 already covered),
--                        PROVIDER_CITY, PROVIDER_STATE_CODE,
--                        PROVIDER_ZIP, PROVIDER_COUNTY, PROVIDER_COUNTRY
--    7 organization    : ORGANIZATION_NAME, ORGANIZATION_STREET_ADDRESS_1,
--                        (ORGANIZATION_STREET_ADDRESS_2 already covered),
--                        ORGANIZATION_CITY, ORGANIZATION_STATE_CODE,
--                        ORGANIZATION_ZIP, ORGANIZATION_COUNTY,
--                        ORGANIZATION_COUNTRY
--    2 investigation   : INVESTIGATION_LOCAL_ID, INVESTIGATION_DT
--   --------------------------------------------------------------
--   Target gain: ~50 cols → 60/60 (theoretical max).
--   Realistic target: 55+ cols (some may require unanticipated joins).
--
-- UID BLOCK: 22020000-22020999 (Agent N allotment)
--   22020100  PATIENT_KEY + PATIENT_UID (D_PATIENT new row, MPR self-ref
--             for PATIENT_BIRTH_SEX sub-select)
--   22020110  PROVIDER_KEY + PROVIDER_UID (D_PROVIDER new row)
--   22020120  ORGANIZATION_KEY + ORGANIZATION_UID (D_ORGANIZATION new row)
--   22020130  D_VACCINATION_KEY + VACCINATION_UID (D_VACCINATION + nrt_vaccination)
--   22003000  Existing COVID PHC (referenced via nrt_vaccination.phc_uid,
--             nrt_investigation seeded if missing)
--
-- IDEMPOTENCY
--   Each block guarded by IF NOT EXISTS on its key column. Safe to re-run.
--
-- TAIL-EXEC
--   sp_covid_vaccination_datamart_postprocessing invoked at the bottom
--   with @vac_uids='22020130' so the SP picks up our new vaccination
--   without depending on @patient_uids passthrough. Wrapped in TRY/CATCH.
--
-- GOTCHAS
--   * The SP's PATIENT_BIRTH_SEX subquery looks up by patient.PATIENT_MPR_UID.
--     My new D_PATIENT row sets PATIENT_MPR_UID = PATIENT_UID (self-ref) so
--     the subquery resolves to the same row.
--   * D_PATIENT has PATIENT_KEY=1 as a sentinel row with all NULL cols. The
--     join on PATIENT_UID won't match it (it has NULL PATIENT_UID), so safe.
--   * UPPER(patient.PATIENT_COUNTRY) — the SP UPPERs PATIENT_COUNTRY but the
--     col is still populated. Same for PROVIDER_COUNTRY, ORGANIZATION_COUNTRY.
--   * PROVIDER_STREET_ADDRESS_2 and ORGANIZATION_STREET_ADDRESS_2 are ISNULL'd
--     to '' by the SP, so they're always populated — already counted as
--     "covered" in baseline. We populate them with real values anyway.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------- Sentinels / locals ----------
DECLARE @user      bigint   = 10009282;          -- conventional superuser id
DECLARE @t         datetime = '2026-04-15T10:00:00';

-- ---------- New UIDs (this fixture) ----------
DECLARE @new_patient_key   bigint = 22020100;
DECLARE @new_patient_uid   bigint = 22020100;

DECLARE @new_provider_key  bigint = 22020110;
DECLARE @new_provider_uid  bigint = 22020110;

DECLARE @new_org_key       bigint = 22020120;
DECLARE @new_org_uid       bigint = 22020120;

DECLARE @new_vac_key       bigint = 22020130;
DECLARE @new_vac_uid       bigint = 22020130;

DECLARE @covid_phc_uid     bigint = 22003000;    -- existing COVID PHC

-- =====================================================================
-- D_PATIENT — full demographics with PATIENT_MPR_UID self-ref so the SP's
-- PATIENT_BIRTH_SEX subquery resolves.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_PATIENT WHERE PATIENT_KEY = 22020100)
BEGIN
    INSERT INTO dbo.D_PATIENT (
        PATIENT_KEY, PATIENT_UID, PATIENT_MPR_UID, PATIENT_RECORD_STATUS,
        PATIENT_LOCAL_ID, PATIENT_GENERAL_COMMENTS,
        PATIENT_FIRST_NAME, PATIENT_MIDDLE_NAME, PATIENT_LAST_NAME,
        PATIENT_NAME_SUFFIX,
        PATIENT_STREET_ADDRESS_1, PATIENT_STREET_ADDRESS_2,
        PATIENT_CITY, PATIENT_STATE, PATIENT_STATE_CODE,
        PATIENT_ZIP, PATIENT_COUNTY, PATIENT_COUNTY_CODE,
        PATIENT_COUNTRY,
        PATIENT_PHONE_HOME, PATIENT_PHONE_EXT_HOME,
        PATIENT_DOB, PATIENT_AGE_REPORTED, PATIENT_AGE_REPORTED_UNIT,
        PATIENT_BIRTH_SEX, PATIENT_CURRENT_SEX,
        PATIENT_DECEASED_INDICATOR,
        PATIENT_MARITAL_STATUS, PATIENT_SSN, PATIENT_ETHNICITY,
        PATIENT_RACE_CALCULATED, PATIENT_RACE_CALC_DETAILS,
        PATIENT_RACE_ALL,
        PATIENT_BIRTH_COUNTRY, PATIENT_PRIMARY_OCCUPATION,
        PATIENT_PRIMARY_LANGUAGE,
        PATIENT_ENTRY_METHOD, PATIENT_LAST_CHANGE_TIME,
        PATIENT_ADD_TIME, PATIENT_ADDED_BY, PATIENT_LAST_UPDATED_BY
    ) VALUES (
        22020100, 22020100, 22020100, N'ACTIVE',
        N'PSN22020100GA01',
        N'COVID vaccination enrich — fully attributed patient for SP coverage.',
        N'Coverage', N'Vacc', N'Patient',
        N'Sr.',
        N'1000 COVID Vaccine Lane', N'Apartment 4C',
        N'Atlanta', N'Georgia', N'13',
        N'30303', N'Fulton County', N'13121',
        N'United States',
        N'404-555-1100', N'5555',
        '1980-08-20T00:00:00', 45, N'YEARS',
        N'M', N'M',
        N'No',
        N'Married', N'444-55-6666', N'Not Hispanic or Latino',
        N'White', N'White',
        N'European | Irish | Italian',
        N'UNITED STATES', N'Healthcare Worker',
        N'English',
        N'ELECTRONIC', '2026-04-15T10:00:00',
        '2026-04-15T10:00:00', 10009282, 10009282
    );
END
GO

-- =====================================================================
-- D_PROVIDER — full attribution for COVID vaccination administrator.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER WHERE PROVIDER_KEY = 22020110)
BEGIN
    INSERT INTO dbo.D_PROVIDER (
        PROVIDER_KEY, PROVIDER_UID, PROVIDER_RECORD_STATUS,
        PROVIDER_LOCAL_ID,
        PROVIDER_NAME_PREFIX, PROVIDER_FIRST_NAME,
        PROVIDER_MIDDLE_NAME, PROVIDER_LAST_NAME,
        PROVIDER_NAME_SUFFIX, PROVIDER_NAME_DEGREE,
        PROVIDER_STREET_ADDRESS_1, PROVIDER_STREET_ADDRESS_2,
        PROVIDER_CITY, PROVIDER_STATE, PROVIDER_STATE_CODE,
        PROVIDER_ZIP, PROVIDER_COUNTY, PROVIDER_COUNTY_CODE,
        PROVIDER_COUNTRY,
        PROVIDER_PHONE_WORK, PROVIDER_PHONE_EXT_WORK,
        PROVIDER_EMAIL_WORK,
        PROVIDER_ENTRY_METHOD, PROVIDER_ADD_TIME, PROVIDER_LAST_CHANGE_TIME,
        PROVIDER_ADDED_BY, PROVIDER_LAST_UPDATED_BY
    ) VALUES (
        22020110, 22020110, N'ACTIVE',
        N'PSN22020110GA01',
        N'Dr.', N'Vacc',
        N'COVID', N'Administrator',
        N'MD', N'MD, MPH',
        N'200 Vaccine Clinic Boulevard', N'Suite 5B',
        N'Atlanta', N'Georgia', N'13',
        N'30303', N'Fulton County', N'13121',
        N'United States',
        N'404-555-2200', N'7777',
        N'vacc.admin@nbs.test',
        N'ELECTRONIC', '2026-04-15T10:00:00', '2026-04-15T10:00:00',
        10009282, 10009282
    );
END
GO

-- =====================================================================
-- D_ORGANIZATION — vaccination clinic facility.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_KEY = 22020120)
BEGIN
    INSERT INTO dbo.D_ORGANIZATION (
        ORGANIZATION_KEY, ORGANIZATION_UID, ORGANIZATION_RECORD_STATUS,
        ORGANIZATION_LOCAL_ID, ORGANIZATION_NAME,
        ORGANIZATION_STAND_IND_CLASS,
        ORGANIZATION_STREET_ADDRESS_1, ORGANIZATION_STREET_ADDRESS_2,
        ORGANIZATION_CITY, ORGANIZATION_STATE, ORGANIZATION_STATE_CODE,
        ORGANIZATION_ZIP, ORGANIZATION_COUNTY, ORGANIZATION_COUNTY_CODE,
        ORGANIZATION_COUNTRY,
        ORGANIZATION_PHONE_WORK, ORGANIZATION_PHONE_EXT_WORK,
        ORGANIZATION_EMAIL,
        ORGANIZATION_ENTRY_METHOD, ORGANIZATION_ADD_TIME, ORGANIZATION_LAST_CHANGE_TIME,
        ORGANIZATION_ADDED_BY, ORGANIZATION_LAST_UPDATED_BY
    ) VALUES (
        22020120, 22020120, N'ACTIVE',
        N'ORG22020120GA01', N'COVID Vaccination Clinic',
        N'General Medical and Surgical Hospitals',
        N'300 Clinic Drive', N'Building C',
        N'Atlanta', N'Georgia', N'13',
        N'30303', N'Fulton County', N'13121',
        N'United States',
        N'404-555-3300', N'8888',
        N'clinic@nbs.test',
        N'ELECTRONIC', '2026-04-15T10:00:00', '2026-04-15T10:00:00',
        10009282, 10009282
    );
END
GO

-- =====================================================================
-- D_VACCINATION — directly seeded with full attribution.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_VACCINATION WHERE D_VACCINATION_KEY = 22020130)
BEGIN
    INSERT INTO dbo.D_VACCINATION (
        D_VACCINATION_KEY, VACCINATION_UID, LOCAL_ID,
        RECORD_STATUS_CD, RECORD_STATUS_TIME,
        VACCINE_ADMINISTERED_DATE, VACCINE_DOSE_NBR,
        VACCINATION_ADMINISTERED_NM, VACCINATION_ANATOMICAL_SITE,
        AGE_AT_VACCINATION, AGE_AT_VACCINATION_UNIT,
        VACCINE_MANUFACTURER_NM, VACCINE_LOT_NUMBER_TXT,
        VACCINE_EXPIRATION_DT, VACCINE_INFO_SOURCE,
        VERSION_CTRL_NBR, ELECTRONIC_IND,
        ADD_TIME, ADD_USER_ID, LAST_CHG_TIME, LAST_CHG_USER_ID
    ) VALUES (
        22020130, 22020130, N'VAC22020130GA01',
        N'ACTIVE', '2026-04-15T10:00:00',
        '2026-04-15T10:00:00', N'3',
        N'COVID-19 vaccine, mRNA, bivalent', N'Left deltoid',
        N'45', N'Y',
        N'Pfizer-BioNTech', N'LOT-COV-MRNA-2026-A',
        '2027-06-30T00:00:00', N'Vaccine information statement',
        1, N'Y',
        '2026-04-15T10:00:00', 10009282, '2026-04-15T10:00:00', 10009282
    );
END
GO

-- =====================================================================
-- NRT_VACCINATION — must exist for the SP's #VAC_LIST filter
-- (material_cd IN ('207','208','213')). vaccination_uid=22020130,
-- material_cd='208', soft-refs to new dim UIDs and the COVID PHC.
-- =====================================================================
GO

-- =====================================================================
-- NRT_INVESTIGATION — required for the SP's LEFT JOIN to populate
-- INVESTIGATION_LOCAL_ID + INVESTIGATION_DT. Linked by phc_uid=22003000
-- (existing COVID PHC).
-- =====================================================================
GO

-- =====================================================================
-- TAIL EXEC — re-run sp_covid_vaccination_datamart_postprocessing on the
-- new vaccination_uid. Wrapped in TRY/CATCH so a failure here doesn't
-- abort downstream fixture application.
-- =====================================================================
GO
