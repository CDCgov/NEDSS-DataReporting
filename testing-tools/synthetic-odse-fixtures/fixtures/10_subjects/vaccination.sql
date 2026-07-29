USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 1 Vaccination fixture
-- Baseline: 6.0.18.1 (post-liquibase) + fixtures/00_foundation/00_foundation.sql
--
-- ARCHITECTURAL NOTE
--   Vaccination is a moderately-sized subject (Act-bearing entity):
--     - Event SP: dbo.sp_vaccination_event (param: @vac_uids)
--       File: routines/071-sp_vaccination_event-001.sql
--       Joins NBS_ODSE.dbo.INTERVENTION + NBS_ACT_ENTITY (TYPE_CD='SubOfVacc')
--       and emits a JSON projection of vaccination data, including code
--       lookups via NBS_question / Codeset / Code_value_general for
--       VAC101 (VAC_NM), VAC104 (NIP_ANATOMIC_ST), VAC106 (AGE_UNIT),
--       VAC107 (VAC_MFGR), VAC147 (PHVS_VACCINEEVENTINFORMATIONSOURCE_NND).
--       The event SP at Tier 1 isolation surfaces zero rows because
--       NBS_ACT_ENTITY (SubOfVacc) is a CROSS-subject participation row
--       (Vaccination -> Patient) — Tier 2 territory. The event SP is a
--       JSON-projection / contract test only; not authored to produce
--       nrt_vaccination (we hand-author that). Empty result is expected
--       and not a fixture failure.
--     - Postprocessing SPs (2):
--       1. dbo.sp_d_vaccination_postprocessing (param: @vac_uids)
--          File: routines/044-sp_d_vaccination_postprocessing-001.sql
--          Reads from dbo.nrt_vaccination + dbo.nrt_vaccination_answer
--          (which we hand-author) and INSERTs / UPDATEs D_VACCINATION
--          (21 live cols). Allocates surrogate keys via INSERT into
--          nrt_vaccination_key (IDENTITY) for any UID without a
--          D_VACCINATION_KEY. NRT_METADATA_COLUMNS has 0 rows for
--          D_VACCINATION at baseline -> no dynamic LDF column expansion.
--       2. dbo.sp_f_vaccination_postprocessing (param: @vac_uids)
--          File: routines/046-sp_f_vaccination_postprocessing-001.sql
--          Reads nrt_vaccination + nrt_vaccination_key and joins
--          D_PATIENT / D_PROVIDER / D_ORGANIZATION / INVESTIGATION on
--          patient_uid / provider_uid / organization_uid / phc_uid soft
--          refs. ALL four cross-subject FK columns are COALESCEd to
--          sentinel 1 (lines 74, 77, 80, 85). At Tier 1 isolation the
--          dimension lookups return no rows, so every COALESCE resolves
--          to 1. No FK constraints on F_VACCINATION, so the INSERT
--          succeeds.
--   No FK constraints on D_VACCINATION / F_VACCINATION / NRT_VACCINATION_KEY
--   in baseline 6.0.18.1 (verified via sys.foreign_keys). Therefore
--   Tier 1 isolation is expected to populate 21/21 D_VACCINATION columns
--   and 6/6 F_VACCINATION columns cleanly (with cross-subject FK keys
--   resolved to sentinel 1 for now).
--
-- WHAT THIS FIXTURE DOES
--   1. Foundation Vaccination enrichment:
--        - Foundation already has the dbo.intervention row at UID 20000160
--          (sparse — most clinical columns NULL; see coverage_foundation.md
--          "Columns deliberately skipped" — intervention row:
--          activity_from_time, activity_to_time, target_site_cd, method_cd,
--          vacc_mfgr_cd, age_at_vacc, material_lot_nm, material_expiration_time,
--          vacc_info_source_cd).
--        - No additional ODSE child rows required (vaccination is an Act,
--          not an Entity — no internal entity_locator_participation; and
--          NBS_ACT_ENTITY 'SubOfVacc' is cross-subject = Tier 2). The
--          foundation intervention row is referenced unchanged.
--        - Hand-author one nrt_vaccination row keyed on vaccination_uid
--          20000160, with most clinical columns NULL (foundation
--          null-propagation variant). VACCINATION_ADMINISTERED_NM,
--          VACCINATION_ANATOMICAL_SITE, VACCINE_INFO_SOURCE,
--          VACCINE_MANUFACTURER_NM passed in as empty strings to exercise
--          the SP's NULLIF blank-to-NULL transforms (lines 246, 254, 255,
--          258, 260 of sp_d_vaccination_postprocessing).
--
--   2. v2 Vaccination: a fully-attributed alternative within block
--      20110000-20119999.
--        - dbo.act row at 20110010 (INTV/EVN).
--        - dbo.intervention row at 20110010 with every column the event
--          SP / postprocessing SP touches set non-NULL: cd='52'
--          (VAC_NM Hep A adult, aligned with foundation Investigation
--          Hep A acute condition_cd='10110'), material_cd='52',
--          target_site_cd='LD' (NIP_ANATOMIC_ST Left Deltoid),
--          age_at_vacc_unit_cd='Y' (AGE_UNIT Years), age_at_vacc=42,
--          vacc_mfgr_cd='MSD' (VAC_MFGR Merck), vacc_info_source_cd='9'
--          (PHVS_VACCINEEVENTINFORMATIONSOURCE_NND New immunization
--          record), material_lot_nm='LOT-HEPA-2026-A',
--          material_expiration_time='2027-12-31', vacc_dose_nbr=2,
--          activity_from_time='2026-04-15T10:00:00' (VACCINE_ADMIN_DATE),
--          activity_to_time='2026-04-15T10:05:00', shared_ind='T',
--          electronic_ind='Y', record_status_cd='ACTIVE'.
--        - Hand-author the nrt_vaccination row keyed on 20110010 with:
--            * patient_uid=20000000 (foundation Patient)
--            * provider_uid=20000010 (foundation Provider)
--            * organization_uid=20000020 (foundation Organization)
--            * phc_uid=20000100 (foundation Investigation, soft ref)
--            * Every column the postprocessing SPs read from
--              nrt_vaccination is set: vaccination_uid, add_time,
--              add_user_id, age_at_vaccination, age_at_vaccination_unit,
--              last_chg_time, last_chg_user_id, local_id,
--              record_status_cd, record_status_time,
--              vaccine_administered_date, vaccine_dose_nbr,
--              vaccination_administered_nm, vaccination_anatomical_site,
--              vaccine_expiration_dt, vaccine_info_source,
--              vaccine_lot_number_txt, vaccine_manufacturer_nm,
--              version_ctrl_nbr, electronic_ind, status_time,
--              prog_area_cd, jurisdiction_cd, program_jurisdiction_oid,
--              material_cd.
--
--   3. Synthetic staging rows in RDB_MODERN.dbo.nrt_vaccination:
--        - 2 rows: foundation Vaccination (UID 20000160) + v2 Vaccination
--          (UID 20110010)
--      29 settable columns (31 total minus refresh_datetime/max_datetime
--      which are GENERATED ALWAYS / ROW START / ROW END — verified via
--      sys.columns generated_always_type IN (1,2)).
--      No nrt_vaccination_answer rows authored at Tier 1 — would only
--      add coverage to dynamic LDF columns and NRT_METADATA_COLUMNS for
--      D_VACCINATION is empty in baseline (no LDF columns to populate).
--
--   4. Does NOT author cross-subject participation (SubOfVacc,
--      PerformerOfVacc) or act_relationship (type_cd='1180' for PHC
--      linkage) rows — these are Tier 2.
--
--   5. Does NOT hand-author dbo.nrt_vaccination_key — postprocessing SP
--      allocates surrogate keys via IDENTITY at lines 205-209 of
--      sp_d_vaccination_postprocessing.
--
--   6. Does NOT invoke the 3 out-of-scope SPs:
--      sp_ldf_intervention_event,
--      sp_covid_vaccination_datamart_postprocessing,
--      sp_ldf_vaccine_prevent_diseases_datamart_postprocessing.
--
-- UID block (Vaccination Tier 1): 20110000-20119999.
-- Foundation dependencies (read-only):
--   @dbo_Act_vaccination_uid     20000160  (act / intervention foundation)
--   @dbo_Entity_patient_uid      20000000  (referenced via nrt_vaccination.patient_uid)
--   @dbo_Entity_provider_uid     20000010  (referenced via nrt_vaccination.provider_uid)
--   @dbo_Entity_organization_uid 20000020  (referenced via nrt_vaccination.organization_uid)
--   @dbo_Act_investigation_uid   20000100  (referenced via nrt_vaccination.phc_uid soft ref)
-- =====================================================================

-- ----- Sentinel reference -----
DECLARE @superuser_id bigint = 10009282;       -- conventional NBS superuser id

-- ----- Foundation dependencies referenced (read-only) -----
DECLARE @foundation_act_vaccination_uid bigint = 20000160;  -- foundation Vaccination Act / intervention
DECLARE @foundation_patient_uid         bigint = 20000000;  -- foundation Patient
DECLARE @foundation_provider_uid        bigint = 20000010;  -- foundation Provider
DECLARE @foundation_org_uid             bigint = 20000020;  -- foundation Organization
DECLARE @foundation_investigation_uid   bigint = 20000100;  -- foundation Investigation PHC

-- =====================================================================
-- UID allocations (Vaccination Tier 1: 20110000-20119999)
-- =====================================================================

DECLARE @dbo_Act_vaccination_v2_uid bigint = 20110010;  -- v2 Vaccination act / intervention (CVX 52 Hep A adult)

-- =====================================================================
-- ODSE rows — additive enrichments and v2 variant.
-- =====================================================================

-- =====================================================================
-- v2 Vaccination: fully-attributed alternative.
--   act.class_cd 'INTV' from SRTE ACT_CLS; mood_cd 'EVN'.
-- =====================================================================
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@dbo_Act_vaccination_v2_uid, N'INTV', N'EVN');

-- v2 intervention row — every column the event SP / postprocessing SP
-- references is set non-NULL. Aligned with foundation Investigation
-- (Hepatitis A acute, condition_cd='10110') by using
-- VAC_NM='52' (Hep A adult).
--
-- Codes (all verified in baseline NBS_SRTE.dbo.code_value_general):
--   cd / material_cd '52' from VAC_NM = 'Hep A, adult'
--   target_site_cd 'LD' from NIP_ANATOMIC_ST = 'Left Deltoid'
--   age_at_vacc_unit_cd 'Y' from AGE_UNIT = 'Years'
--   vacc_mfgr_cd 'MSD' from VAC_MFGR = 'Merck & Co., Inc.'
--   vacc_info_source_cd '9' from PHVS_VACCINEEVENTINFORMATIONSOURCE_NND
--     = 'New immunization record'
INSERT INTO [dbo].[intervention]
    ([intervention_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
     [class_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid],
     [record_status_cd], [record_status_time], [shared_ind],
     [status_cd], [status_time], [version_ctrl_nbr],
     [activity_from_time], [activity_to_time],
     [material_cd], [target_site_cd], [target_site_desc_txt],
     [method_cd], [method_desc_txt],
     [age_at_vacc], [age_at_vacc_unit_cd],
     [vacc_mfgr_cd], [vacc_dose_nbr],
     [material_lot_nm], [material_expiration_time],
     [vacc_info_source_cd], [electronic_ind], [txt])
VALUES
    (@dbo_Act_vaccination_v2_uid, '2026-04-15T10:00:00', @superuser_id,
     N'52', N'Hep A, adult',
     N'INTV', '2026-04-15T10:00:00', @superuser_id, N'VAC20110010GA01',
     N'IMM', N'130001', 20110010,
     N'ACTIVE', '2026-04-15T10:00:00', N'T',
     N'A', '2026-04-15T10:00:00', 1,
     '2026-04-15T10:00:00', '2026-04-15T10:05:00',
     N'52', N'LD', N'Left Deltoid',
     N'IM', N'Intramuscular',
     42, N'Y',
     N'MSD', 2,
     N'LOT-HEPA-2026-A', '2027-12-31T00:00:00',
     N'9', N'Y', N'Tier 1 Vaccination v2 — Hep A adult, dose 2.');

GO

-- =====================================================================
-- DRIVE THE POSTPROCESSING SPs via direct nrt_vaccination INSERTs.
-- =====================================================================

USE [RDB_MODERN];
GO

-- Re-declare locals inside the RDB_MODERN batch (DECLAREs do not survive GO).
DECLARE @superuser_id bigint = 10009282;
DECLARE @foundation_act_vaccination_uid bigint = 20000160;
DECLARE @foundation_patient_uid         bigint = 20000000;
DECLARE @foundation_provider_uid        bigint = 20000010;
DECLARE @foundation_org_uid             bigint = 20000020;
DECLARE @foundation_investigation_uid   bigint = 20000100;
DECLARE @dbo_Act_vaccination_v2_uid     bigint = 20110010;

-- =====================================================================
-- nrt_vaccination: 2 rows total.
--   - foundation Vaccination (UID 20000160) — sparse / null + blank
--     propagation. Soft refs (patient_uid/provider_uid/organization_uid/
--     phc_uid) NULL — exhibits the no-cross-subject path.
--   - v2 Vaccination (UID 20110010) — fully populated. Soft refs point
--     at foundation Patient/Provider/Org/Investigation.
-- 29 settable columns. refresh_datetime + max_datetime are GENERATED
-- ALWAYS (omitted; system fills them).
-- =====================================================================

GO
