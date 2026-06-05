-- =====================================================================
-- Tier 3 (Round 5, item C) — COVID dedicated rich patient/provider/org
--                            + repointed participations for PHC 22003000
-- =====================================================================
-- ODSE-ONLY, ADDITIVE, NO shared-dim UPDATE.
--
-- GOAL
--   Fill the ~27 "shared-dim" NULL columns of covid_case_datamart for the
--   COVID full-chain investigation 22003000:
--     PATIENT_* (D_PATIENT / NRT_PATIENT, routine 310 Step 5 #COVID_PATIENT_DATA)
--     PHC_INV_*  (investigator  -> D_PROVIDER, Step 6 #COVID_ENTITIES_DATA)
--     PHYS_*     (physician     -> D_PROVIDER)
--     RPT_PRV_*  (person reporter -> D_PROVIDER)
--     RPT_ORG_*  (org reporter   -> D_ORGANIZATION)
--     HOSPITAL_NAME (hospital    -> D_ORGANIZATION)
--
-- WHY THE COLUMNS WERE NULL (verified live 2026-06-04)
--   The only participation on PHC 22003000 was a single SubjOfPHC ->
--   foundation patient 20000000 (sparse demographics), authored by
--   zz_investigation_patient_links.sql. There were ZERO
--   InvestgrOfPHC / PhysicianOfPHC / PerAsReporterOfPHC participations,
--   ZERO organization participations, and ZERO nbs_act_entity rows for
--   22003000. So NRT_INVESTIGATION 22003000 had investigator_id /
--   physician_id / person_as_reporter_uid / organization_id /
--   hospital_uid all NULL and patient_id = sparse 20000000.
--
-- HOW THE PIPELINE PROJECTS THESE (NO nrt_* / EXEC sp_ in this fixture)
--   On aw/remove-nrt-shortcut the FULL pipeline runs: ODSE -> Debezium CDC
--   -> kafka-connect -> nrt_* -> reporting-pipeline-service sp_*_event +
--   sp_nrt_*_postprocessing. Specifically:
--     * sp_patient_event / sp_provider_event / sp_organization_event emit
--       the entity JSON; kafka-connect writes nrt_patient / nrt_provider /
--       nrt_organization; sp_nrt_*_postprocessing build D_PATIENT /
--       D_PROVIDER / D_ORGANIZATION. (Same shape as the Tier-1 canaries
--       fixtures/10_subjects/{patient,provider,organization}.sql.)
--     * sp_investigation_event (routine 056) projects person_participations
--       + organization_participations JSON for the PHC; the service's
--       ProcessInvestigationDataUtil maps them onto nrt_investigation
--       (verified ProcessInvestigationDataUtil.java:211-292):
--         InvestgrOfPHC  + PSN + person_cd='PRV' -> investigator_id
--         PhysicianOfPHC + PSN + person_cd='PRV' -> physician_id
--         SubjOfPHC      + PSN + person_cd='PAT' -> patient_id
--         PerAsReporterOfPHC + PSN + person_cd='PRV' -> person_as_reporter_uid
--         OrgAsReporterOfPHC (ORG) -> organization_id
--         HospOfADT          (ORG) -> hospital_uid
--       NOTE the person_participations JSON join (056:356-359) resolves the
--       person via person_parent_uid, and person_cd comes from that parent.
--       So each provider person is self-parented with cd='PRV', the patient
--       self-parented with cd='PAT'.
--     * We ALSO author the matching nbs_act_entity rows (PerAsReporterOfPHC /
--       OrgAsReporterOfPHC / HospOfADT) for 22003000, mirroring
--       fixtures/20_links/phc_roles_nae.sql, because routine 056's
--       investigation_act_entity CASE-pivot (056:909-934) reads those edge
--       UIDs from nbs_act_entity (belt-and-suspenders with the JSON path).
--
-- SUPERSEDING THE SHARED-FOUNDATION SubjOfPHC (allowed — investigation's
-- own link row, NOT a shared dim)
--   We DELETE the existing SubjOfPHC(22003000 -> 20000000) row and INSERT a
--   fresh SubjOfPHC(22003000 -> 22055000 = new rich COVID patient). This
--   touches only THIS investigation's link row; D_PATIENT/person 20000000
--   and every other investigation that links 20000000 are untouched. Other
--   COVID fixtures that reference 20000000 do so via ct_contact.subject_*
--   (hard-set, independent of this participation), so they are unaffected.
--   Idempotent: the DELETE/INSERT are guarded so re-apply is a no-op.
--
-- UID block: 22055000 - 22055999 (reserved in catalog/uid_ranges.md R5-C).
--   22055000           rich COVID patient (entity/person, cd='PAT')
--   22055001-22055006  patient locators (home addr/birth/home phone/work phone/cell/email)
--   22055010           investigator provider (entity/person, cd='PRV')
--   22055011-22055013  investigator locators (work addr/work phone/cell)
--   22055020           physician provider (entity/person, cd='PRV')
--   22055021-22055023  physician locators (work addr/work phone/cell)
--   22055030           person-reporter provider (entity/person, cd='PRV')
--   22055031-22055033  reporter-person locators (work addr/work phone/cell)
--   22055040           reporter organization (entity/organization)
--   22055041-22055042  reporter-org locators (work addr/work phone)
--   22055050           hospital organization (entity/organization)
--   22055051-22055052  hospital locators (work addr/work phone)
--   nbs_act_entity_uid is IDENTITY (NOT flood-prone per IDENTITY_REFACTOR_PLAN);
--   we let it AUTO-assign and guard on the natural key (act_uid, entity_uid,
--   type_cd) per LESSON 11.
--
-- Foundation dependencies (read-only):
--   @superuser_id 10009282 ; COVID PHC 22003000 (act/public_health_case).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @covid_phc_uid bigint = 22003000;

-- ----- UID allocations (block 22055000-22055999) -----
DECLARE @pat_uid        bigint = 22055000;   -- rich COVID patient (PSN/PAT)
DECLARE @pat_pst_home   bigint = 22055001;   -- patient home address (PST,H,H)
DECLARE @pat_pst_bir    bigint = 22055002;   -- patient birth country (PST,BIR,BIR)
DECLARE @pat_tel_home   bigint = 22055003;   -- patient home phone (TELE,H,PH)
DECLARE @pat_tel_work   bigint = 22055004;   -- patient work phone (TELE,WP,PH) + ext
DECLARE @pat_tel_cell   bigint = 22055005;   -- patient cell phone (TELE,*,CP)
DECLARE @pat_tel_email  bigint = 22055006;   -- patient email (TELE,H,NET)

DECLARE @inv_uid        bigint = 22055010;   -- investigator provider (PSN/PRV)
DECLARE @inv_pst        bigint = 22055011;   -- investigator work address (PST,WP,O)
DECLARE @inv_tel_work   bigint = 22055012;   -- investigator work phone (TELE,WP,O) + ext
DECLARE @inv_tel_cell   bigint = 22055013;   -- investigator cell phone (TELE,CP,*)

DECLARE @phys_uid       bigint = 22055020;   -- physician provider (PSN/PRV)
DECLARE @phys_pst       bigint = 22055021;   -- physician work address (PST,WP,O)
DECLARE @phys_tel_work  bigint = 22055022;   -- physician work phone (TELE,WP,O) + ext
DECLARE @phys_tel_cell  bigint = 22055023;   -- physician cell phone (TELE,CP,*)

DECLARE @rpt_prv_uid    bigint = 22055030;   -- person reporter provider (PSN/PRV)
DECLARE @rpt_prv_pst    bigint = 22055031;   -- reporter work address (PST,WP,O)
DECLARE @rpt_prv_tel_w  bigint = 22055032;   -- reporter work phone (TELE,WP,O) + ext
DECLARE @rpt_prv_tel_c  bigint = 22055033;   -- reporter cell phone (TELE,CP,*)

DECLARE @rpt_org_uid    bigint = 22055040;   -- reporter organization (ORG)
DECLARE @rpt_org_pst    bigint = 22055041;   -- reporter org work address (PST,WP,O)
DECLARE @rpt_org_tel    bigint = 22055042;   -- reporter org work phone (TELE,WP,PH) + ext

DECLARE @hosp_org_uid   bigint = 22055050;   -- hospital organization (ORG)
DECLARE @hosp_org_pst   bigint = 22055051;   -- hospital org work address (PST,WP,O)
DECLARE @hosp_org_tel   bigint = 22055052;   -- hospital org work phone (TELE,WP,PH)

-- =====================================================================
-- (1) RICH COVID PATIENT  -> D_PATIENT / NRT_PATIENT -> PATIENT_* cols
--     Mirrors fixtures/10_subjects/patient.sql v2 (20020010), self-parented
--     cd='PAT'. Populates: middle_nm, nm_suffix, description(general
--     comments), marital_status_cd, age_reported/_unit_cd, deceased_*,
--     curr_sex, ethnicity, race (root+detail), full address, home/work/cell
--     phone + work-ext, email.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = @pat_uid)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@pat_uid, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id],
         [birth_gender_cd], [birth_time], [cd], [curr_sex_cd], [deceased_ind_cd], [deceased_time],
         [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [version_ctrl_nbr],
         [as_of_date_general], [as_of_date_admin], [as_of_date_ethnicity],
         [as_of_date_morbidity], [as_of_date_sex],
         [electronic_ind], [person_parent_uid], [edx_ind],
         [age_reported], [age_reported_unit_cd],
         [marital_status_cd], [education_level_cd], [occupation_cd],
         [prim_lang_cd], [speaks_english_cd], [ethnic_unk_reason_cd], [sex_unk_reason_cd],
         [description])
    VALUES
        (@pat_uid, '2026-04-01T00:00:00', @superuser_id,
         N'M', '1978-09-22T00:00:00', N'PAT', N'M', N'Y', '2026-04-02T12:00:00',
         N'2186-5', '2026-04-01T00:00:00', @superuser_id, N'PSN22055000GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Carlos', N'Andre', N'Vega', N'SR', 1,
         '2026-04-01T00:00:00', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         N'N', @pat_uid, N'Y',
         N'47', N'Y',
         N'M', N'BD', N'622110',
         N'ENG', N'Y', N'6', N'D',
         N'COVID-19 dedicated index patient — Round 5 item C');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@pat_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'Carlos', N'Andre', N'Vega', N'SR', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    -- entity_id (SS).
    INSERT INTO [dbo].[entity_id]
        ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
    VALUES
        (@pat_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         '2026-04-01T00:00:00', @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'222-33-4444', N'SS', N'Social Security', '2026-04-01T00:00:00');

    -- person_race: White root + Hispanic-context detail (root + detail under one category).
    INSERT INTO [dbo].[person_race]
        ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [as_of_date])
    VALUES
        (@pat_uid, N'2106-3', N'2106-3', '2026-04-01T00:00:00', @superuser_id,
         '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', '2026-04-01T00:00:00');

    -- Locators.
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [street_addr2], [zip_cd], [census_tract], [within_city_limits_ind])
    VALUES
        (@pat_pst_home, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
         N'840', N'13121', '2026-04-01T00:00:00', @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'710 Pandemic Parkway', N'Unit 12', N'30303', N'1210320', N'Y');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_pst_bir, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
         N'840', '2026-04-01T00:00:00', @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_tel_home, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'404-555-5000', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tel_work, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'404-555-5001', N'7788',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tel_cell, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'404-555-5002', NULL,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [email_address],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_tel_email, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'carlos.vega@nbs.test',
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@pat_uid, @pat_pst_home, '2026-04-01T00:00:00', @superuser_id, N'H',
         N'PST', '2026-04-01T00:00:00', @superuser_id, N'patient home address',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_pst_bir, '2026-04-01T00:00:00', @superuser_id, N'BIR',
         N'PST', '2026-04-01T00:00:00', @superuser_id, N'patient birth country',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'BIR', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_home, '2026-04-01T00:00:00', @superuser_id, N'PH',
         N'TELE', '2026-04-01T00:00:00', @superuser_id, N'patient home phone',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_work, '2026-04-01T00:00:00', @superuser_id, N'PH',
         N'TELE', '2026-04-01T00:00:00', @superuser_id, N'patient work phone',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_cell, '2026-04-01T00:00:00', @superuser_id, N'CP',
         N'TELE', '2026-04-01T00:00:00', @superuser_id, N'patient cell phone',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_email, '2026-04-01T00:00:00', @superuser_id, N'NET',
         N'TELE', '2026-04-01T00:00:00', @superuser_id, N'patient email',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (2) THREE DEDICATED PROVIDER PERSONS (cd='PRV', self-parented) ->
--     D_PROVIDER -> PHC_INV_*, PHYS_*, RPT_PRV_* cols.
--     Each carries first/middle/last names + work phone (TELE,WP,O) WITH
--     extension (PHYS_TEL_WORK / PHYS_TEL_EXT_WORK / RPT_PRV_TEL_*).
--     Filters per sp_provider_event: phone_work/email_work need (TELE,O,WP);
--     address (PST,O,WP); cell (TELE,CP,*).
-- =====================================================================
DECLARE @superuser_id2 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = 22055010)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
        (22055010, N'PSN'), (22055020, N'PSN'), (22055030, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id], [cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
         [version_ctrl_nbr], [as_of_date_general],
         [electronic_ind], [person_parent_uid], [edx_ind], [description])
    VALUES
        -- Investigator
        (22055010, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         '2026-04-01T00:00:00', @superuser_id2, N'PSN22055010GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Iris', N'N', N'Investigator', N'MS', NULL,
         1, '2026-04-01T00:00:00', N'N', 22055010, N'Y',
         N'COVID dedicated investigator'),
        -- Physician
        (22055020, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         '2026-04-01T00:00:00', @superuser_id2, N'PSN22055020GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Pedro', N'H', N'Physician', N'DR', NULL,
         1, '2026-04-01T00:00:00', N'N', 22055020, N'Y',
         N'COVID dedicated physician'),
        -- Person reporter
        (22055030, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         '2026-04-01T00:00:00', @superuser_id2, N'PSN22055030GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Rachel', N'P', N'Reporter', N'MS', NULL,
         1, '2026-04-01T00:00:00', N'N', 22055030, N'Y',
         N'COVID dedicated person-reporter');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (22055010, 1, '2026-04-01T00:00:00', @superuser_id2, N'Iris', N'N', N'Investigator', N'MS', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (22055020, 1, '2026-04-01T00:00:00', @superuser_id2, N'Pedro', N'H', N'Physician', N'DR', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (22055030, 1, '2026-04-01T00:00:00', @superuser_id2, N'Rachel', N'P', N'Reporter', N'MS', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    -- Work addresses (PST,O,WP).
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [zip_cd])
    VALUES
        (22055011, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'1 Public Health Plaza', N'30303'),
        (22055021, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'2 Clinic Court', N'30303'),
        (22055031, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'3 Reporter Row', N'30303');

    -- Work phones (TELE,O,WP) WITH extension + cell phones (TELE,CP,*).
    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (22055012, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-5510', N'1010',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22055013, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-5511', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22055022, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-5520', N'2020',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22055023, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-5521', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22055032, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-5530', N'3030',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22055033, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-5531', NULL,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        -- investigator
        (22055010, 22055011, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id2, N'inv work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055010, 22055012, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'inv work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055010, 22055013, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'inv cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        -- physician
        (22055020, 22055021, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id2, N'phys work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055020, 22055022, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'phys work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055020, 22055023, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'phys cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        -- reporter
        (22055030, 22055031, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id2, N'rpt work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055030, 22055032, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'rpt work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055030, 22055033, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'rpt cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (3) TWO DEDICATED ORGANIZATIONS -> D_ORGANIZATION ->
--     RPT_ORG_NAME / RPT_ORG_TEL_WORK / RPT_ORG_TEL_EXT_WORK + HOSPITAL_NAME.
--     Filters per sp_organization_event: address (PST,WP,O), phone (TELE,WP,PH).
-- =====================================================================
DECLARE @superuser_id3 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[organization] WHERE organization_uid = 22055040)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
        (22055040, N'ORG'), (22055050, N'ORG');

    INSERT INTO [dbo].[organization]
        ([organization_uid], [add_time], [add_user_id], [description],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [display_nm], [version_ctrl_nbr], [electronic_ind],
         [standard_industry_class_cd], [standard_industry_desc_txt], [edx_ind])
    VALUES
        (22055040, '2026-04-01T00:00:00', @superuser_id3, N'COVID dedicated reporting org',
         '2026-04-01T00:00:00', @superuser_id3, N'ORG22055040GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Peachtree Public Health Reporting Lab', 1, N'Y',
         N'621511', N'Medical Laboratories', N'Y'),
        (22055050, '2026-04-01T00:00:00', @superuser_id3, N'COVID dedicated admitting hospital',
         '2026-04-01T00:00:00', @superuser_id3, N'ORG22055050GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Grady Memorial COVID Unit', 1, N'Y',
         N'622110', N'General Medical and Surgical Hospitals', N'Y');

    INSERT INTO [dbo].[organization_name]
        ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd],
         [record_status_cd], [default_nm_ind])
    VALUES
        (22055040, 1, N'Peachtree Public Health Reporting Lab', N'L', N'ACTIVE', N'Y'),
        (22055050, 1, N'Grady Memorial COVID Unit', N'L', N'ACTIVE', N'Y');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [zip_cd])
    VALUES
        (22055041, '2026-04-01T00:00:00', @superuser_id3, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id3, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'40 Reporting Lab Blvd', N'30303'),
        (22055051, '2026-04-01T00:00:00', @superuser_id3, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id3, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'50 Hospital Drive', N'30303');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (22055042, '2026-04-01T00:00:00', @superuser_id3, N'1',
         '2026-04-01T00:00:00', @superuser_id3, N'404-555-5540', N'4040',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22055052, '2026-04-01T00:00:00', @superuser_id3, N'1',
         '2026-04-01T00:00:00', @superuser_id3, N'404-555-5550', N'5050',
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (22055040, 22055041, '2026-04-01T00:00:00', @superuser_id3, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id3, N'rpt org addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055040, 22055042, '2026-04-01T00:00:00', @superuser_id3, N'PH', N'TELE',
         '2026-04-01T00:00:00', @superuser_id3, N'rpt org phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055050, 22055051, '2026-04-01T00:00:00', @superuser_id3, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id3, N'hosp addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22055050, 22055052, '2026-04-01T00:00:00', @superuser_id3, N'PH', N'TELE',
         '2026-04-01T00:00:00', @superuser_id3, N'hosp phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (4) REPOINT PHC 22003000's PERSON PARTICIPATIONS to the new entities.
--     - Supersede the shared-foundation SubjOfPHC (-> 20000000) with one
--       to the new rich patient 22055000 (allowed: investigation's own
--       link row, not a shared dim).
--     - Add InvestgrOfPHC / PhysicianOfPHC / PerAsReporterOfPHC.
--     subject_class_cd='PSN'; act_class_cd='CASE'. Person participations
--     surface in routine 056's person_participations JSON; the service
--     maps them onto nrt_investigation per ProcessInvestigationDataUtil.
-- =====================================================================
DECLARE @superuser_id4 bigint = 10009282;
DECLARE @covid_phc bigint = 22003000;

-- Supersede the foundation SubjOfPHC for THIS investigation only.
DELETE FROM [dbo].[participation]
WHERE act_uid = @covid_phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 20000000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @covid_phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 22055000)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@covid_phc, 22055000, N'SubjOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id4, '2026-04-01T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Subject of Public Health Case');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @covid_phc AND type_cd = 'InvestgrOfPHC' AND subject_entity_uid = 22055010)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@covid_phc, 22055010, N'InvestgrOfPHC', N'CASE', N'PSN',
     '2026-04-02T00:00:00', '2026-04-02T00:00:00', @superuser_id4, '2026-04-02T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-02T00:00:00', N'A', '2026-04-02T00:00:00', N'Investigator');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @covid_phc AND type_cd = 'PhysicianOfPHC' AND subject_entity_uid = 22055020)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@covid_phc, 22055020, N'PhysicianOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', @superuser_id4, '2026-04-01T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Physician');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @covid_phc AND type_cd = 'PerAsReporterOfPHC' AND subject_entity_uid = 22055030)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@covid_phc, 22055030, N'PerAsReporterOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id4, '2026-04-01T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Person as Reporter');
GO

-- =====================================================================
-- (5) ORGANIZATION PARTICIPATIONS for PHC 22003000.
--     OrgAsReporterOfPHC -> organization_id ; HospOfADT -> hospital_uid.
--     subject_class_cd='ORG'.
-- =====================================================================
DECLARE @superuser_id5 bigint = 10009282;
DECLARE @covid_phc5 bigint = 22003000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @covid_phc5 AND type_cd = 'OrgAsReporterOfPHC' AND subject_entity_uid = 22055040)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@covid_phc5, 22055040, N'OrgAsReporterOfPHC', N'CASE', N'ORG',
     '2026-04-01T00:00:00', @superuser_id5, '2026-04-01T00:00:00', @superuser_id5,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Organization as Reporter');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @covid_phc5 AND type_cd = 'HospOfADT' AND subject_entity_uid = 22055050)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@covid_phc5, 22055050, N'HospOfADT', N'CASE', N'ORG',
     '2026-04-01T00:00:00', @superuser_id5, '2026-04-01T00:00:00', @superuser_id5,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Hospital of ADT');
GO

-- =====================================================================
-- (6) nbs_act_entity edges for PHC 22003000 (belt-and-suspenders with the
--     organization_participations JSON path — routine 056's
--     investigation_act_entity CASE-pivot at 056:909-934 reads these).
--     nbs_act_entity_uid is IDENTITY (NOT flood-prone — IDENTITY_REFACTOR_PLAN
--     section 1: no auto-insert source). LESSON 11: let IDENTITY auto-assign,
--     guard on the natural key (act_uid, entity_uid, type_cd).
-- =====================================================================
DECLARE @superuser_id6 bigint = 10009282;
DECLARE @covid_phc6 bigint = 22003000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @covid_phc6 AND entity_uid = 22055030 AND type_cd = 'PerAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@covid_phc6, 22055030, N'PerAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id6, '2026-04-01T00:00:00', @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @covid_phc6 AND entity_uid = 22055040 AND type_cd = 'OrgAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@covid_phc6, 22055040, N'OrgAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id6, '2026-04-01T00:00:00', @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @covid_phc6 AND entity_uid = 22055050 AND type_cd = 'HospOfADT')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@covid_phc6, 22055050, N'HospOfADT', 1,
     '2026-04-01T00:00:00', @superuser_id6, '2026-04-01T00:00:00', @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');
GO

-- =====================================================================
-- (7) CDC RE-TRIGGER: bump public_health_case.last_chg_time so the
--     Debezium/connect chain re-emits PHC 22003000 -> the service re-runs
--     sp_investigation_event and rebuilds nrt_investigation with the new
--     patient_id / investigator_id / physician_id / person_as_reporter_uid /
--     organization_id / hospital_uid. (This is the investigation's OWN row;
--     not a shared dim. No nrt_*/EXEC sp_ here.)
-- =====================================================================
UPDATE [dbo].[public_health_case]
SET last_chg_time = '2026-06-04T00:00:01'
WHERE public_health_case_uid = 22003000;
GO
