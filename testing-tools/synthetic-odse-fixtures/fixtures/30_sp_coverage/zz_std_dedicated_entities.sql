-- =====================================================================
-- Tier 3 (Round 5, item C — STD) — STD dedicated rich patient/provider/org
--                            + repointed participations for PHC 22004000
-- =====================================================================
-- ODSE-ONLY, ADDITIVE, NO shared-dim UPDATE.
--
-- This is the STD twin of zz_covid_dedicated_entities.sql (commit f26dc05b,
-- COVID PHC 22003000). Same pattern, same pipeline wiring, STD-flavored
-- values; UID block 22057xxx instead of 22055xxx.
--
-- GOAL
--   Fill the "shared-dim" NULL columns of std_hiv_datamart (routine 026
--   sp_std_hiv_datamart_postprocessing) for the STD Syphilis-primary
--   full-chain investigation 22004000 (cond 10311, PG_STD_Investigation):
--     PATIENT_*  (~36 cols)  PAT = D_PATIENT, joined in 026 on PC.PATIENT_KEY
--                            (F_STD_PAGE_CASE), 026:536. PC.PATIENT_KEY comes
--                            from D_PATIENT on nrt_investigation.patient_id
--                            (025:180/215). Filter PC.PATIENT_KEY != 1
--                            (026:566) requires a REAL patient -> a dedicated
--                            rich D_PATIENT row populates all PATIENT_* cols.
--     INVESTIGATOR_CURRENT_KEY = PC.INVESTIGATOR_KEY (026:336)
--     INVESTIGATOR_CURRENT_QC  = CRNTI.PROVIDER_QUICK_CODE
--                            (D_PROVIDER on PC.INVESTIGATOR_KEY, 026:337/539)
--     PHYSICIAN_KEY      = PC.PHYSICIAN_KEY        (026:448)
--     HOSPITAL_KEY       = PC.HOSPITAL_KEY         (026:315)
--     REPORTING_ORG_KEY  = PC.ORG_AS_REPORTER_KEY  (026:451)
--     REPORTING_PROV_KEY = PC.PERSON_AS_REPORTER_KEY (026:452)
--   025 derives those PC keys from nrt_investigation.investigator_id /
--   physician_id / hospital_uid / organization_id / person_as_reporter_uid
--   (025:180-191 join D_PROVIDER/D_ORGANIZATION on PROVIDER_UID/
--   ORGANIZATION_UID; 025:215-225).
--
-- WHY THE COLUMNS WERE NULL
--   The only participation on PHC 22004000 was a single SubjOfPHC ->
--   foundation patient 20000000 (sparse demographics), authored by
--   zz_investigation_patient_links.sql. There were ZERO
--   InvestgrOfPHC / PhysicianOfPHC / PerAsReporterOfPHC participations and
--   ZERO organization participations for 22004000. So
--   nrt_investigation 22004000 had investigator_id / physician_id /
--   person_as_reporter_uid / organization_id / hospital_uid all NULL and
--   patient_id = sparse 20000000 (D_PATIENT row demographically thin).
--
-- HOW THE PIPELINE PROJECTS THESE (NO nrt_* / EXEC sp_ in this fixture)
--   The FULL pipeline runs: ODSE -> Debezium CDC -> kafka-connect -> nrt_*
--   -> reporting-pipeline-service sp_*_event + sp_nrt_*_postprocessing:
--     * sp_patient_event / sp_provider_event / sp_organization_event emit
--       entity JSON; kafka-connect writes nrt_patient / nrt_provider /
--       nrt_organization; sp_nrt_*_postprocessing build D_PATIENT /
--       D_PROVIDER / D_ORGANIZATION. (Same shape as the Tier-1 canaries
--       fixtures/10_subjects/{patient,provider,organization}.sql.)
--     * sp_investigation_event (routine 056) projects person_participations
--       + organization_participations JSON for the PHC; the service's
--       ProcessInvestigationDataUtil maps them onto nrt_investigation
--       (ProcessInvestigationDataUtil.java:211-292):
--         InvestgrOfPHC  + PSN + person_cd='PRV' -> investigator_id
--         PhysicianOfPHC + PSN + person_cd='PRV' -> physician_id
--         SubjOfPHC      + PSN + person_cd='PAT' -> patient_id
--         PerAsReporterOfPHC + PSN + person_cd='PRV' -> person_as_reporter_uid
--         OrgAsReporterOfPHC (ORG) -> organization_id
--         HospOfADT          (ORG) -> hospital_uid
--       056:356-359 resolves person_cd via person_parent_uid (the JSON join
--       reads cd FROM the PARENT person). So each provider person is
--       self-parented with cd='PRV', the patient self-parented with cd='PAT'.
--     * We ALSO author the matching nbs_act_entity edges (PerAsReporterOfPHC /
--       OrgAsReporterOfPHC / HospOfADT) for 22004000 (056's
--       investigation_act_entity CASE-pivot at 056:909-934 reads those edge
--       UIDs from nbs_act_entity — belt-and-suspenders with the JSON path).
--
-- SUPERSEDING THE SHARED-FOUNDATION SubjOfPHC (allowed — investigation's own
-- link row, NOT a shared dim)
--   zz_investigation_patient_links.sql sorts BEFORE this file and (until the
--   coordinated edit in this round) authored SubjOfPHC(22004000 -> 20000000).
--   We (a) removed 22004000 from that fixture's IN-list, AND (b) here DELETE
--   any SubjOfPHC(22004000 -> 20000000) and INSERT a fresh SubjOfPHC(22004000
--   -> 22057000 = new rich STD patient). Belt-and-suspenders so re-apply /
--   run-order is idempotent and there is EXACTLY ONE SubjOfPHC for 22004000.
--   D_PATIENT/person 20000000 and every other investigation linking 20000000
--   are untouched. The std_hiv chain's nrt_investigation patient_id literal
--   is rebuilt by the service from this participation (CDC re-trigger below).
--
-- UID block: 22057000 - 22057999 (reserved in catalog/uid_ranges.md R5 STD-C).
--   22057000           rich STD patient (entity/person, cd='PAT')
--   22057001-22057006  patient locators (home addr/birth/home phone/work phone/cell/email)
--   22057010           investigator provider (entity/person, cd='PRV')
--   22057011-22057013  investigator locators (work addr/work phone/cell)
--   22057020           physician provider (entity/person, cd='PRV')
--   22057021-22057023  physician locators (work addr/work phone/cell)
--   22057030           person-reporter provider (entity/person, cd='PRV')
--   22057031-22057033  reporter-person locators (work addr/work phone/cell)
--   22057040           reporter organization (entity/organization)
--   22057041-22057042  reporter-org locators (work addr/work phone)
--   22057050           hospital organization (entity/organization)
--   22057051-22057052  hospital locators (work addr/work phone)
--   nbs_act_entity_uid is IDENTITY (NOT flood-prone per IDENTITY_REFACTOR_PLAN);
--   let it AUTO-assign and guard on the natural key (act_uid, entity_uid,
--   type_cd) per LESSON 10/11.
--
-- Foundation dependencies (read-only):
--   @superuser_id 10009282 ; STD PHC 22004000 (act/public_health_case,
--   authored in std_hiv_investigation_full_chain.sql).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- UID allocations (block 22057000-22057999) -----
DECLARE @pat_uid        bigint = 22057000;   -- rich STD patient (PSN/PAT)
DECLARE @pat_pst_home   bigint = 22057001;   -- patient home address (PST,H,H)
DECLARE @pat_pst_bir    bigint = 22057002;   -- patient birth country (PST,BIR,BIR)
DECLARE @pat_tel_home   bigint = 22057003;   -- patient home phone (TELE,H,PH)
DECLARE @pat_tel_work   bigint = 22057004;   -- patient work phone (TELE,WP,PH) + ext
DECLARE @pat_tel_cell   bigint = 22057005;   -- patient cell phone (TELE,*,CP)
DECLARE @pat_tel_email  bigint = 22057006;   -- patient email (TELE,H,NET)

DECLARE @inv_uid        bigint = 22057010;   -- investigator provider (PSN/PRV)
DECLARE @inv_pst        bigint = 22057011;   -- investigator work address (PST,WP,O)
DECLARE @inv_tel_work   bigint = 22057012;   -- investigator work phone (TELE,WP,O) + ext
DECLARE @inv_tel_cell   bigint = 22057013;   -- investigator cell phone (TELE,CP,*)

DECLARE @phys_uid       bigint = 22057020;   -- physician provider (PSN/PRV)
DECLARE @phys_pst       bigint = 22057021;   -- physician work address (PST,WP,O)
DECLARE @phys_tel_work  bigint = 22057022;   -- physician work phone (TELE,WP,O) + ext
DECLARE @phys_tel_cell  bigint = 22057023;   -- physician cell phone (TELE,CP,*)

DECLARE @rpt_prv_uid    bigint = 22057030;   -- person reporter provider (PSN/PRV)
DECLARE @rpt_prv_pst    bigint = 22057031;   -- reporter work address (PST,WP,O)
DECLARE @rpt_prv_tel_w  bigint = 22057032;   -- reporter work phone (TELE,WP,O) + ext
DECLARE @rpt_prv_tel_c  bigint = 22057033;   -- reporter cell phone (TELE,CP,*)

DECLARE @rpt_org_uid    bigint = 22057040;   -- reporter organization (ORG)
DECLARE @rpt_org_pst    bigint = 22057041;   -- reporter org work address (PST,WP,O)
DECLARE @rpt_org_tel    bigint = 22057042;   -- reporter org work phone (TELE,WP,PH) + ext

DECLARE @hosp_org_uid   bigint = 22057050;   -- hospital organization (ORG)
DECLARE @hosp_org_pst   bigint = 22057051;   -- hospital org work address (PST,WP,O)
DECLARE @hosp_org_tel   bigint = 22057052;   -- hospital org work phone (TELE,WP,PH)

-- =====================================================================
-- (1) RICH STD PATIENT  -> D_PATIENT -> PATIENT_* cols.
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
         N'M', '1992-06-14T00:00:00', N'PAT', N'M', N'N', NULL,
         N'2186-5', '2026-04-01T00:00:00', @superuser_id, N'PSN22057000GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Marcus', N'Ellis', N'Harlow', N'JR', 1,
         '2026-04-01T00:00:00', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         N'N', @pat_uid, N'Y',
         N'33', N'Y',
         N'S', N'BD', N'412110',
         N'ENG', N'Y', N'6', N'D',
         N'STD Syphilis-primary dedicated index patient — Round 5 item C (STD)');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@pat_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'Marcus', N'Ellis', N'Harlow', N'JR', N'L',
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
         N'333-44-5555', N'SS', N'Social Security', '2026-04-01T00:00:00');

    -- person_race: Black/African-American root + detail under one category.
    INSERT INTO [dbo].[person_race]
        ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [as_of_date])
    VALUES
        (@pat_uid, N'2054-5', N'2054-5', '2026-04-01T00:00:00', @superuser_id,
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
         N'820 Magnolia Street', N'Apt 4B', N'30310', N'1210400', N'Y');

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
         '2026-04-01T00:00:00', @superuser_id, N'404-555-7000', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tel_work, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'404-555-7001', N'4422',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tel_cell, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'404-555-7002', NULL,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [email_address],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_tel_email, '2026-04-01T00:00:00', @superuser_id, N'1',
         '2026-04-01T00:00:00', @superuser_id, N'marcus.harlow@nbs.test',
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
--     D_PROVIDER -> INVESTIGATOR_CURRENT_*, PHYSICIAN_KEY, REPORTING_PROV_KEY.
--     Filters per sp_provider_event: phone_work/email_work need (TELE,O,WP);
--     address (PST,O,WP); cell (TELE,CP,*).
-- =====================================================================
DECLARE @superuser_id2 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = 22057010)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
        (22057010, N'PSN'), (22057020, N'PSN'), (22057030, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id], [cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
         [version_ctrl_nbr], [as_of_date_general],
         [electronic_ind], [person_parent_uid], [edx_ind], [description])
    VALUES
        -- Investigator
        (22057010, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         '2026-04-01T00:00:00', @superuser_id2, N'PSN22057010GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Nadia', N'S', N'Investigator', N'MS', NULL,
         1, '2026-04-01T00:00:00', N'N', 22057010, N'Y',
         N'STD dedicated investigator'),
        -- Physician
        (22057020, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         '2026-04-01T00:00:00', @superuser_id2, N'PSN22057020GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Owen', N'T', N'Physician', N'DR', NULL,
         1, '2026-04-01T00:00:00', N'N', 22057020, N'Y',
         N'STD dedicated physician'),
        -- Person reporter
        (22057030, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         '2026-04-01T00:00:00', @superuser_id2, N'PSN22057030GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Tara', N'L', N'Reporter', N'MS', NULL,
         1, '2026-04-01T00:00:00', N'N', 22057030, N'Y',
         N'STD dedicated person-reporter');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (22057010, 1, '2026-04-01T00:00:00', @superuser_id2, N'Nadia', N'S', N'Investigator', N'MS', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (22057020, 1, '2026-04-01T00:00:00', @superuser_id2, N'Owen', N'T', N'Physician', N'DR', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (22057030, 1, '2026-04-01T00:00:00', @superuser_id2, N'Tara', N'L', N'Reporter', N'MS', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    -- Work addresses (PST,O,WP).
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [zip_cd])
    VALUES
        (22057011, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'10 STD Program Plaza', N'30303'),
        (22057021, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'20 Sexual Health Clinic Way', N'30303'),
        (22057031, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'30 Reporter Row', N'30303');

    -- Work phones (TELE,O,WP) WITH extension + cell phones (TELE,CP,*).
    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (22057012, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-7710', N'1010',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22057013, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-7711', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22057022, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-7720', N'2020',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22057023, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-7721', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22057032, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-7730', N'3030',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22057033, '2026-04-01T00:00:00', @superuser_id2, N'1',
         '2026-04-01T00:00:00', @superuser_id2, N'404-555-7731', NULL,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        -- investigator
        (22057010, 22057011, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id2, N'inv work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057010, 22057012, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'inv work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057010, 22057013, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'inv cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        -- physician
        (22057020, 22057021, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id2, N'phys work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057020, 22057022, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'phys work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057020, 22057023, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'phys cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        -- reporter
        (22057030, 22057031, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id2, N'rpt work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057030, 22057032, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'rpt work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057030, 22057033, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         '2026-04-01T00:00:00', @superuser_id2, N'rpt cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (3) TWO DEDICATED ORGANIZATIONS -> D_ORGANIZATION ->
--     REPORTING_ORG_KEY + HOSPITAL_KEY.
--     Filters per sp_organization_event: address (PST,WP,O), phone (TELE,WP,PH).
-- =====================================================================
DECLARE @superuser_id3 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[organization] WHERE organization_uid = 22057040)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
        (22057040, N'ORG'), (22057050, N'ORG');

    INSERT INTO [dbo].[organization]
        ([organization_uid], [add_time], [add_user_id], [description],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [display_nm], [version_ctrl_nbr], [electronic_ind],
         [standard_industry_class_cd], [standard_industry_desc_txt], [edx_ind])
    VALUES
        (22057040, '2026-04-01T00:00:00', @superuser_id3, N'STD dedicated reporting org',
         '2026-04-01T00:00:00', @superuser_id3, N'ORG22057040GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Fulton County STD Surveillance Lab', 1, N'Y',
         N'621511', N'Medical Laboratories', N'Y'),
        (22057050, '2026-04-01T00:00:00', @superuser_id3, N'STD dedicated admitting hospital',
         '2026-04-01T00:00:00', @superuser_id3, N'ORG22057050GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Grady Memorial Sexual Health Center', 1, N'Y',
         N'622110', N'General Medical and Surgical Hospitals', N'Y');

    INSERT INTO [dbo].[organization_name]
        ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd],
         [record_status_cd], [default_nm_ind])
    VALUES
        (22057040, 1, N'Fulton County STD Surveillance Lab', N'L', N'ACTIVE', N'Y'),
        (22057050, 1, N'Grady Memorial Sexual Health Center', N'L', N'ACTIVE', N'Y');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [zip_cd])
    VALUES
        (22057041, '2026-04-01T00:00:00', @superuser_id3, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id3, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'41 Surveillance Lab Blvd', N'30303'),
        (22057051, '2026-04-01T00:00:00', @superuser_id3, N'Atlanta', N'840', N'13121',
         '2026-04-01T00:00:00', @superuser_id3, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'51 Sexual Health Center Drive', N'30303');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (22057042, '2026-04-01T00:00:00', @superuser_id3, N'1',
         '2026-04-01T00:00:00', @superuser_id3, N'404-555-7740', N'4040',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22057052, '2026-04-01T00:00:00', @superuser_id3, N'1',
         '2026-04-01T00:00:00', @superuser_id3, N'404-555-7750', N'5050',
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (22057040, 22057041, '2026-04-01T00:00:00', @superuser_id3, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id3, N'rpt org addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057040, 22057042, '2026-04-01T00:00:00', @superuser_id3, N'PH', N'TELE',
         '2026-04-01T00:00:00', @superuser_id3, N'rpt org phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057050, 22057051, '2026-04-01T00:00:00', @superuser_id3, N'O', N'PST',
         '2026-04-01T00:00:00', @superuser_id3, N'hosp addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22057050, 22057052, '2026-04-01T00:00:00', @superuser_id3, N'PH', N'TELE',
         '2026-04-01T00:00:00', @superuser_id3, N'hosp phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (4) REPOINT PHC 22004000's PERSON PARTICIPATIONS to the new entities.
--     - Supersede the shared-foundation SubjOfPHC (-> 20000000) with one
--       to the new rich patient 22057000 (allowed: investigation's own
--       link row, not a shared dim).
--     - Add InvestgrOfPHC / PhysicianOfPHC / PerAsReporterOfPHC.
--     subject_class_cd='PSN'; act_class_cd='CASE'. Person participations
--     surface in routine 056's person_participations JSON; the service
--     maps them onto nrt_investigation per ProcessInvestigationDataUtil.
-- =====================================================================
DECLARE @superuser_id4 bigint = 10009282;
DECLARE @std_phc bigint = 22004000;

-- Supersede the foundation SubjOfPHC for THIS investigation only.
DELETE FROM [dbo].[participation]
WHERE act_uid = @std_phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 20000000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @std_phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 22057000)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@std_phc, 22057000, N'SubjOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id4, '2026-04-01T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Subject of Public Health Case');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @std_phc AND type_cd = 'InvestgrOfPHC' AND subject_entity_uid = 22057010)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@std_phc, 22057010, N'InvestgrOfPHC', N'CASE', N'PSN',
     '2026-04-02T00:00:00', '2026-04-02T00:00:00', @superuser_id4, '2026-04-02T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-02T00:00:00', N'A', '2026-04-02T00:00:00', N'Investigator');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @std_phc AND type_cd = 'PhysicianOfPHC' AND subject_entity_uid = 22057020)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@std_phc, 22057020, N'PhysicianOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', @superuser_id4, '2026-04-01T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Physician');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @std_phc AND type_cd = 'PerAsReporterOfPHC' AND subject_entity_uid = 22057030)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@std_phc, 22057030, N'PerAsReporterOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id4, '2026-04-01T00:00:00', @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Person as Reporter');
GO

-- =====================================================================
-- (5) ORGANIZATION PARTICIPATIONS for PHC 22004000.
--     OrgAsReporterOfPHC -> organization_id ; HospOfADT -> hospital_uid.
--     subject_class_cd='ORG'.
-- =====================================================================
DECLARE @superuser_id5 bigint = 10009282;
DECLARE @std_phc5 bigint = 22004000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @std_phc5 AND type_cd = 'OrgAsReporterOfPHC' AND subject_entity_uid = 22057040)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@std_phc5, 22057040, N'OrgAsReporterOfPHC', N'CASE', N'ORG',
     '2026-04-01T00:00:00', @superuser_id5, '2026-04-01T00:00:00', @superuser_id5,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Organization as Reporter');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @std_phc5 AND type_cd = 'HospOfADT' AND subject_entity_uid = 22057050)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@std_phc5, 22057050, N'HospOfADT', N'CASE', N'ORG',
     '2026-04-01T00:00:00', @superuser_id5, '2026-04-01T00:00:00', @superuser_id5,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Hospital of ADT');
GO

-- =====================================================================
-- (6) nbs_act_entity edges for PHC 22004000 (belt-and-suspenders with the
--     organization_participations JSON path — routine 056's
--     investigation_act_entity CASE-pivot at 056:909-934 reads these).
--     nbs_act_entity_uid is IDENTITY (NOT flood-prone — IDENTITY_REFACTOR_PLAN
--     section 1: no auto-insert source). LESSON 10/11: let IDENTITY
--     auto-assign, guard on the natural key (act_uid, entity_uid, type_cd).
-- =====================================================================
DECLARE @superuser_id6 bigint = 10009282;
DECLARE @std_phc6 bigint = 22004000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @std_phc6 AND entity_uid = 22057030 AND type_cd = 'PerAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@std_phc6, 22057030, N'PerAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id6, '2026-04-01T00:00:00', @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @std_phc6 AND entity_uid = 22057040 AND type_cd = 'OrgAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@std_phc6, 22057040, N'OrgAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id6, '2026-04-01T00:00:00', @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @std_phc6 AND entity_uid = 22057050 AND type_cd = 'HospOfADT')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@std_phc6, 22057050, N'HospOfADT', 1,
     '2026-04-01T00:00:00', @superuser_id6, '2026-04-01T00:00:00', @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');
GO

-- =====================================================================
-- (7) CDC RE-TRIGGER: bump public_health_case.last_chg_time so the
--     Debezium/connect chain re-emits PHC 22004000 -> the service re-runs
--     sp_investigation_event and rebuilds nrt_investigation with the new
--     patient_id / investigator_id / physician_id / person_as_reporter_uid /
--     organization_id / hospital_uid. (This is the investigation's OWN row;
--     not a shared dim. No nrt_*/EXEC sp_ here.)
-- =====================================================================
UPDATE [dbo].[public_health_case]
SET last_chg_time = '2026-06-04T00:00:02'
WHERE public_health_case_uid = 22004000;
GO
