USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 3 NO-SHORTCUT fixture — COVID_VACCINATION_DATAMART gap close
-- =====================================================================
-- Agent: R6 tick 6 (covid_vaccination).   UID block: 22072000-22072999.
-- Branch: aw/remove-nrt-shortcut (NO nrt_* INSERTs, NO EXEC sp_, ODSE-only).
--
-- TARGET (live RDB_MODERN, 2026-06-04): covid_vaccination_datamart is
-- 39/60 populated; the 21 NULL columns are:
--   VACCINE FAMILY (8)  : VACCINATION_ANATOMICAL_SITE, VACCINE_ADMINISTERED_DATE,
--                         VACCINE_EXPIRATION_DT, VACCINE_INFO_SOURCE,
--                         VACCINE_LOT_NUMBER_TXT, VACCINE_MANUFACTURER_NM,
--                         AGE_AT_VACCINATION, AGE_AT_VACCINATION_UNIT
--   INVESTIGATION (2)   : INVESTIGATION_DT, INVESTIGATION_LOCAL_ID
--   ORGANIZATION (7)    : ORGANIZATION_NAME, ORGANIZATION_STREET_ADDRESS_1,
--                         ORGANIZATION_CITY, ORGANIZATION_STATE_CODE,
--                         ORGANIZATION_ZIP, ORGANIZATION_COUNTY,
--                         ORGANIZATION_COUNTRY
--   PATIENT/PROVIDER(4) : PATIENT_MIDDLE_NAME, OCCUPATION (PATIENT_PRIMARY_OCCUPATION),
--                         PROVIDER_NAME_DEGREE, PATIENT_SSN
--
-- WHY THE EXISTING DATAMART ROW IS SPARSE
--   The single committed row is the foundation Vaccination
--   (vaccination_uid=20000160, material_cd='207') hand-authored by the
--   shortcut-era Tier-1 fixture: nrt_vaccination has NULL
--   patient_uid/provider_uid/organization_uid/phc_uid soft-refs and the
--   D_VACCINATION row carries no anatomical-site / lot / mfgr / etc., so
--   every column above reads NULL.
--
-- THE NO-SHORTCUT VACCINATION ODSE PATH (verified against routines)
--   ODSE intervention (INTV/EVN) + nbs_act_entity + act_relationship
--     --CDC--> sp_vaccination_event (071)  -- builds NRT_VACCINATION from:
--        * INTERVENTION columns (material_cd, target_site_cd, age_at_vacc[_unit_cd],
--          vacc_mfgr_cd, vacc_info_source_cd, material_lot_nm,
--          material_expiration_time, vacc_dose_nbr, activity_from_time, ...)
--          with code lookups VAC101/104/106/107/147 -> the VACCINE_* names.
--        * nbs_act_entity TYPE_CD='SubOfVacc'       (INTV->Person/PAT)  -> PATIENT_UID
--        * nbs_act_entity TYPE_CD='PerformerOfVacc' (INTV->Person/PRV)  -> PROVIDER_UID
--        * nbs_act_entity TYPE_CD='PerformerOfVacc' (INTV->Organization)-> ORGANIZATION_UID
--        * act_relationship TYPE_CD='1180'          (INTV->PHC)         -> PHC_UID
--     --> sp_d_vaccination_postprocessing (044)  -- D_VACCINATION (VACCINE_* cols)
--     --> sp_f_vaccination_postprocessing (046)  -- F_VACCINATION
--     --> sp_covid_vaccination_datamart_postprocessing (320)  -- the datamart,
--         gated on NRT_VACCINATION.material_cd IN ('207','208','213'), joining
--         D_VACCINATION / D_PATIENT / D_PROVIDER / D_ORGANIZATION and reading
--         INVESTIGATION_DT/INVESTIGATION_LOCAL_ID from NRT_INVESTIGATION by phc_uid.
--   Bug #20 (obs-batch fail-fast) is FIXED, so this VACCINATION-class act no
--   longer risks fail-fast collateral on lower-priority entities.
--
-- WHAT THIS FIXTURE AUTHORS (all ODSE, all in 22072xxx, all additive)
--   * dbo.act + dbo.intervention  22072000  -- a COVID-19 vaccination
--     (material_cd='208' SARS-COV-2 mRNA) with EVERY vaccine attribute set
--     so the 8 VACCINE_* columns + AGE_AT_VACCINATION[_UNIT] land.
--   * A dedicated PROVIDER person 22072020 with person_name.nm_degree
--     ('MD, PhD') so PROVIDER_NAME_DEGREE lands (the existing COVID
--     dedicated providers 22055020/030 carry NULL nm_degree).
--   * nbs_act_entity (IDENTITY_INSERT, surrogate UIDs 22072100-22072102):
--       SubOfVacc        intervention 22072000 -> COVID dedicated PATIENT 22055000
--                        (rich: middle_nm 'Andre', occupation -> PATIENT_MIDDLE_NAME + OCCUPATION)
--       PerformerOfVacc  intervention 22072000 -> dedicated PROVIDER  22072020 (degree)
--       PerformerOfVacc  intervention 22072000 -> COVID dedicated ORG  22055050
--                        (Grady Memorial COVID Unit, full Atlanta address -> 7 ORGANIZATION_* cols)
--   * act_relationship TYPE_CD='1180': intervention 22072000 -> COVID PHC 22003000
--     (existing covid_investigation_full_chain PHC; cd='11065') so the datamart's
--     INVESTIGATION_DT + INVESTIGATION_LOCAL_ID resolve from NRT_INVESTIGATION 22003000.
--   * Closing last_chg_time bump on the COVID PHC 22003000 act row to
--     re-trigger CDC for the linked investigation/vaccination edge.
--
-- READ-ONLY FOUNDATION DEPENDENCIES (never modified)
--   22055000  COVID dedicated PATIENT (Person/PAT) -- middle_nm + occupation already in D_PATIENT
--   22055050  COVID dedicated ORGANIZATION         -- full address already in D_ORGANIZATION
--   22003000  COVID PHC (public_health_case/act)   -- INVESTIGATION_KEY=8, nrt_investigation present
--
-- CODES (verified live in NBS_SRTE.dbo.code_value_general via the event SP's
-- VAC101/104/106/107/147 lookup):
--   material_cd          '208'  VAC101  SARS-COV-2 (COVID-19) vaccine, mRNA
--   target_site_cd       'LD'   VAC104  Left Deltoid       -> VACCINATION_ANATOMICAL_SITE
--   age_at_vacc_unit_cd  'Y'    VAC106  Years              -> AGE_AT_VACCINATION_UNIT
--   vacc_mfgr_cd         'MOD'  VAC107  Moderna US, Inc.   -> VACCINE_MANUFACTURER_NM
--   vacc_info_source_cd  '9'    VAC147  New immunization record -> VACCINE_INFO_SOURCE
--
-- LANDING CONFIDENCE
--   HIGH (19 cols): 8 VACCINE_*, AGE_AT_VACCINATION[_UNIT], 2 INVESTIGATION,
--     7 ORGANIZATION, PATIENT_MIDDLE_NAME, OCCUPATION, PROVIDER_NAME_DEGREE.
--   LOW  (1 col): PATIENT_SSN -- the COVID dedicated patient 22055000 carries
--     entity_id (type_cd='SS', root '222-33-4444') yet NRT_PATIENT.ssn / D_PATIENT.
--     PATIENT_SSN are NULL on this branch (service-side SS extraction quirk),
--     so PATIENT_SSN is effectively out of reach without touching the shared
--     patient chain. Documented; not chased.
--
-- IDEMPOTENCY: every block guarded by NOT EXISTS on its own UID. Safe to re-run.
-- GENERATED ALWAYS period cols omitted throughout.
-- =====================================================================

DECLARE @superuser_id bigint = 10009282;

-- ----- this fixture's UIDs (22072xxx) -----
DECLARE @vac_uid        bigint = 22072000;   -- COVID vaccination intervention / act
DECLARE @prov_uid       bigint = 22072020;   -- dedicated provider (Person/PRV) with nm_degree

-- ----- read-only foundation deps -----
DECLARE @pat_uid        bigint = 22055000;   -- COVID dedicated patient (Person/PAT)
DECLARE @org_uid        bigint = 22055050;   -- COVID dedicated organization (Grady Memorial COVID Unit)
DECLARE @covid_phc_uid  bigint = 22003000;   -- COVID PHC (act / public_health_case)

-- =====================================================================
-- (1) Dedicated PROVIDER person 22072020 -- carries person_name.nm_degree
--     so the provider chain (sp_provider_event -> nrt_provider.name_degree
--     -> D_PROVIDER.PROVIDER_NAME_DEGREE) populates PROVIDER_NAME_DEGREE.
--     Mirrors the COVID dedicated-provider shape (cd='PRV', self-parented),
--     adding nm_degree which 22055020/030 omit.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = @prov_uid)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@prov_uid, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id], [cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_prefix],
         [version_ctrl_nbr], [as_of_date_general],
         [electronic_ind], [person_parent_uid], [edx_ind], [description])
    VALUES
        (@prov_uid, '2026-04-15T10:00:00', @superuser_id, N'PRV',
         '2026-04-15T10:00:00', @superuser_id, N'PSN22072020GA01',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
         N'Victor', N'A', N'Vaxgiver', N'DR',
         1, '2026-04-15T10:00:00', N'N', @prov_uid, N'Y',
         N'COVID vaccination administering provider (gap-close, degree-bearing)');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_degree], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@prov_uid, 1, '2026-04-15T10:00:00', @superuser_id,
         N'Victor', N'A', N'Vaxgiver', N'DR', N'MD, PhD', N'L',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00');
END
GO

-- Re-declare locals after GO.
DECLARE @superuser_id bigint = 10009282;
DECLARE @vac_uid       bigint = 22072000;

-- =====================================================================
-- (2) COVID vaccination act + intervention 22072000.
--     act: class_cd='INTV' (SRTE ACT_CLS), mood_cd='EVN'.
--     intervention: every column the event SP reads is set non-NULL.
--       material_cd='208'  -> COVID gate (datamart material filter) + VAC101 name
--       target_site_cd='LD', age_at_vacc=53/'Y', vacc_mfgr_cd='MOD',
--       vacc_info_source_cd='9', material_lot_nm, material_expiration_time,
--       vacc_dose_nbr=3, activity_from_time (VACCINE_ADMINISTERED_DATE).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[act] WHERE act_uid = @vac_uid)
    INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd])
    VALUES (@vac_uid, N'INTV', N'EVN');
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @vac_uid       bigint = 22072000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[intervention] WHERE intervention_uid = @vac_uid)
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
        (@vac_uid, '2026-04-15T10:00:00', @superuser_id,
         N'208', N'SARS-COV-2 (COVID-19) vaccine, mRNA',
         N'INTV', '2026-04-15T10:00:00', @superuser_id, N'VAC22072000GA01',
         N'IMM', N'130001', 22072000,
         N'ACTIVE', '2026-04-15T10:00:00', N'T',
         N'A', '2026-04-15T10:00:00', 1,
         '2026-04-15T10:00:00', '2026-04-15T10:10:00',
         N'208', N'LD', N'Left Deltoid',
         N'IM', N'Intramuscular',
         53, N'Y',
         N'MOD', 3,
         N'LOT-COV-MRNA-2026-G', '2027-09-30T00:00:00',
         N'9', N'Y', N'COVID-19 vaccination gap-close, Moderna mRNA, dose 3, left deltoid.');
GO

-- =====================================================================
-- (3) nbs_act_entity cross-subject edges (IDENTITY column -> IDENTITY_INSERT
--     with surrogate UIDs from this block). The event SP gates on:
--       SubOfVacc        (main FROM INNER JOIN, line 108) -> PATIENT_UID
--       PerformerOfVacc + Person   -> PROVIDER_UID  (line 1135)
--       PerformerOfVacc + Organization -> ORGANIZATION_UID (line 1146)
-- =====================================================================
DECLARE @superuser_id bigint = 10009282;
DECLARE @vac_uid       bigint = 22072000;
DECLARE @prov_uid      bigint = 22072020;
DECLARE @pat_uid       bigint = 22055000;
DECLARE @org_uid       bigint = 22055050;

SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity] WHERE nbs_act_entity_uid = 22072100)
    INSERT INTO [dbo].[nbs_act_entity]
        ([nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
         [entity_version_ctrl_nbr],
         [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time])
    VALUES
        -- SubOfVacc: COVID vaccination -> COVID dedicated patient
        (22072100, @vac_uid, @pat_uid, N'SubOfVacc', 1,
         '2026-04-15T10:00:00', @superuser_id, '2026-04-15T10:00:00', @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00'),
        -- PerformerOfVacc (Person): COVID vaccination -> dedicated provider (degree)
        (22072101, @vac_uid, @prov_uid, N'PerformerOfVacc', 1,
         '2026-04-15T10:00:00', @superuser_id, '2026-04-15T10:00:00', @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00'),
        -- PerformerOfVacc (Organization): COVID vaccination -> COVID dedicated org
        (22072102, @vac_uid, @org_uid, N'PerformerOfVacc', 1,
         '2026-04-15T10:00:00', @superuser_id, '2026-04-15T10:00:00', @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00');

SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
GO

-- =====================================================================
-- (4) act_relationship TYPE_CD='1180': COVID vaccination -> COVID PHC.
--     The event SP CASE_INFO CTE (line 1160) projects PHC_UID from
--     act_relationship where SOURCE_ACT_UID=vaccination and TYPE_CD='1180',
--     which flows to NRT_VACCINATION.phc_uid; the datamart then reads
--     INVESTIGATION_DT + INVESTIGATION_LOCAL_ID from NRT_INVESTIGATION 22003000.
--     source_class_cd='INTV' (vaccination), target_class_cd='CASE' (PHC).
-- =====================================================================
DECLARE @superuser_id bigint = 10009282;
DECLARE @vac_uid       bigint = 22072000;
DECLARE @covid_phc_uid bigint = 22003000;

IF NOT EXISTS (
    SELECT 1 FROM [dbo].[act_relationship]
    WHERE source_act_uid = @vac_uid AND target_act_uid = @covid_phc_uid AND type_cd = N'1180')
    INSERT INTO [dbo].[act_relationship]
        ([source_act_uid], [target_act_uid], [type_cd], [type_desc_txt],
         [source_class_cd], [target_class_cd], [sequence_nbr],
         [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@vac_uid, @covid_phc_uid, N'1180', N'Vaccination of Public Health Case',
         N'INTV', N'CASE', 1,
         '2026-04-15T10:00:00', @superuser_id, '2026-04-15T10:00:00', @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00');
GO

-- =====================================================================
-- (5) Closing CDC re-trigger: bump last_chg_time on the COVID PHC act so the
--     investigation/vaccination edge re-emits a CDC change and the service
--     re-processes the linked vaccination through the postprocessing +
--     covid_vaccination_datamart SPs. (act has no last_chg_time; bump the
--     public_health_case row, which IS CDC-captured.)
-- =====================================================================
DECLARE @covid_phc_uid bigint = 22003000;

UPDATE [dbo].[public_health_case]
SET [last_chg_time] = '2026-04-15T10:15:00'
WHERE public_health_case_uid = @covid_phc_uid;
GO
