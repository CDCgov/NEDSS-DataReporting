-- =====================================================================
-- Tier 3 (Round 5, item C — TB) — TB dedicated rich patient/provider/org
--                            + repointed participations for PHC 22001000
-- =====================================================================
-- ODSE-ONLY, ADDITIVE, NO shared-dim UPDATE.
--
-- This is the TB twin of zz_covid_dedicated_entities.sql (COVID PHC 22003000)
-- and zz_std_dedicated_entities.sql (STD PHC 22004000). Same pattern, same
-- pipeline wiring, TB-flavored values; UID block 22058xxx.
--
-- GOAL
--   Fill the "shared-dim" NULL columns of tb_datamart (routine 255
--   sp_tb_datamart_postprocessing) AND tb_hiv_datamart (routine 260) for the
--   TB RVCT full-chain investigation 22001000 (cond 10220 Tuberculosis,
--   prog_area_cd TB, investigation_form_cd INV_FORM_RVCT):
--     PATIENT_*  (~25 cols)  255 #PATIENT: D_PATIENT p JOIN F_TB_PAM f
--                            ON p.PATIENT_KEY = f.PERSON_KEY (255:164-166).
--                            f.PERSON_KEY <- F_TB_PAM, derived in routine 206
--                            from D_PATIENT on INVESTIGATION.patient_id
--                            (206:64 MAX(I.patient_id)=PERSON_UID, 206:103
--                            join D_PATIENT). A dedicated rich D_PATIENT row
--                            populates all PATIENT_* cols.
--     INVESTIGATOR_FIRST/LAST_NAME, INVESTIGATOR_PHONE_NUMBER
--                            255 #PROVIDER: D_PROVIDER p ON
--                            p.PROVIDER_KEY = f.PROVIDER_KEY (255:198-202);
--                            f.PROVIDER_KEY <- 206:60 MAX(I.investigator_id)
--                            =PROVIDER_UID, 206:133-136 join D_PROVIDER.
--     PHYSICIAN_FIRST/LAST_NAME, PHYSICIAN_PHONE_NUMBER, PHYSICIAN_KEY
--                            255 #PHYSICIAN: D_PROVIDER ON
--                            p.PROVIDER_KEY = f.PHYSICIAN_KEY (255:237-238);
--                            f.PHYSICIAN_KEY <- 206:65 MAX(I.physician_id),
--                            206:545-552 join D_PROVIDER.
--     REPORTER_FIRST/LAST_NAME, REPORTER_PHONE_NUMBER, PERSON_AS_REPORTER_KEY
--                            255 #REPORTER: D_PROVIDER r ON
--                            r.PROVIDER_KEY = f.PERSON_AS_REPORTER_KEY
--                            (255:274-275); f.PERSON_AS_REPORTER_KEY <- 206:63
--                            MAX(I.person_as_reporter_uid), 206:515-520.
--     REPORTING_SOURCE_NAME  255 #REPORTING_ORG: D_ORGANIZATION o ON
--                            o.ORGANIZATION_KEY = f.ORG_AS_REPORTER_KEY
--                            (255:309-310); f.ORG_AS_REPORTER_KEY <- 206:61
--                            MAX(I.org_as_reporter_uid), 206:482-487.
--     HOSPITAL_NAME, HOSPITAL_KEY
--                            255 #HOSPITAL: D_ORGANIZATION o ON
--                            o.ORGANIZATION_KEY = f.HOSPITAL_KEY (255:343-344);
--                            f.HOSPITAL_KEY <- I.hospital_uid, 206:450-453.
--
--   tb_hiv_datamart (routine 260) inherits ALL these columns: 260 builds
--   #TB_HIV_DATAMART as `d.* FROM TB_DATAMART d` (260:161-166), i.e. it COPIES
--   the just-built tb_datamart row for the same investigation. So filling
--   tb_datamart's PATIENT_*/INVESTIGATOR_*/PHYSICIAN_*/REPORTING/HOSPITAL cols
--   AUTOMATICALLY fills the identically-named tb_hiv_datamart cols. One set of
--   dedicated entities solves BOTH datamarts.
--
-- WHY THE COLUMNS WERE NULL (before this fixture)
--   PHC 22001000's only person participation was a single SubjOfPHC ->
--   foundation patient 20000000 (sparse demographics: no SSN / middle name /
--   suffix / within-city / Asian-race detail), authored by
--   zz_investigation_patient_links.sql. There were ZERO InvestgrOfPHC /
--   PhysicianOfPHC participations -> INVESTIGATION.investigator_id /
--   physician_id NULL -> INVESTIGATOR_*/PHYSICIAN_* NULL. The reporter/org/
--   hospital came from zz_tb_fact_chain.sql's nbs_act_entity edges pointing at
--   foundation entities 20000010/20000020 (thin). So all PATIENT_*/
--   INVESTIGATOR_*/PHYSICIAN_*/REPORTING/HOSPITAL dim cols read NULL or thin.
--
-- HOW THE PIPELINE PROJECTS THESE (NO nrt_* / EXEC sp_ in this fixture)
--   FULL pipeline: ODSE -> Debezium CDC -> kafka-connect -> nrt_* ->
--   reporting-pipeline-service sp_*_event + sp_nrt_*_postprocessing:
--     * sp_patient_event / sp_provider_event / sp_organization_event emit
--       entity JSON; kafka-connect writes nrt_patient / nrt_provider /
--       nrt_organization; sp_nrt_*_postprocessing build D_PATIENT /
--       D_PROVIDER / D_ORGANIZATION.
--     * sp_investigation_event (routine 056) projects person_participations
--       JSON for the PHC (056:339-361); the service's
--       ProcessInvestigationDataUtil maps them onto INVESTIGATION /
--       nrt_investigation (ProcessInvestigationDataUtil.java:211-292):
--         InvestgrOfPHC  + PSN + person_cd='PRV' -> investigator_id
--         PhysicianOfPHC + PSN + person_cd='PRV' -> physician_id
--         SubjOfPHC      + PSN + person_cd='PAT' -> patient_id
--         PerAsReporterOfPHC + PSN + person_cd='PRV' -> person_as_reporter_uid
--       056:356-359 resolves person_cd via person_parent_uid (the JSON join
--       reads cd FROM the PARENT person). So each provider person is
--       self-parented with cd='PRV', the patient self-parented with cd='PAT'.
--     * org_as_reporter_uid / hospital_uid / person_as_reporter_uid are ALSO
--       carried by 056's investigation_act_entity CASE-pivot over
--       nbs_act_entity (056:909-934):
--         org_as_reporter_uid    = MAX(entity_uid WHERE type_cd='OrgAsReporterOfPHC')
--         hospital_uid           = MAX(entity_uid WHERE type_cd='HospOfADT')
--         person_as_reporter_uid = MAX(entity_uid WHERE type_cd='PerAsReporterOfPHC')
--       GROUPED BY act_uid. zz_tb_fact_chain.sql already authored these three
--       edges pointing at FOUNDATION entities 20000020/20000010 (to set
--       nac_page_case_uid so F_TB_PAM has a key). We add a SECOND set of edges
--       for the SAME three type_cds pointing at our NEW dedicated org/hosp/
--       reporter (22058040/22058050/22058030). Because 056 uses MAX(entity_uid)
--       per type_cd and 22058xxx > 20000xxx, OUR entities WIN deterministically
--       -> org_as_reporter_uid=22058040, hospital_uid=22058050,
--       person_as_reporter_uid=22058030. nac_page_case_uid stays 22001000
--       (MAX(act_uid) over the group is unchanged). We do NOT touch
--       zz_tb_fact_chain's rows (they keep nac_page_case_uid set regardless of
--       run order); ours are purely additive and override only via MAX.
--
-- SUPERSEDING THE SHARED-FOUNDATION SubjOfPHC (allowed — investigation's own
-- link row, NOT a shared dim)
--   zz_investigation_patient_links.sql sorts BEFORE this file and (until the
--   coordinated edit in this round) authored SubjOfPHC(22001000 -> 20000000).
--   We (a) removed 22001000 from that fixture's IN-list, AND (b) here DELETE
--   any SubjOfPHC(22001000 -> 20000000) and INSERT a fresh SubjOfPHC(22001000
--   -> 22058000 = new rich TB patient). Belt-and-suspenders so re-apply /
--   run-order is idempotent and there is EXACTLY ONE SubjOfPHC for 22001000.
--   D_PATIENT/person 20000000 and every other investigation linking 20000000
--   are untouched.
--
-- DO NOT DISTURB 22050000 — that is the SECOND TB investigation authored by
--   zz_tb_datamart_fill.sql (page-answer-derived TB cols). This fixture touches
--   ONLY the ORIGINAL TB PHC 22001000 and its own new 22058xxx entities.
--
-- UID block: 22058000 - 22058999 (reserved in catalog/uid_ranges.md R5 TB-C).
--   22058000           rich TB patient (entity/person, cd='PAT')
--   22058001-22058006  patient locators (home addr/birth/home phone/work phone/cell/email)
--   22058010           investigator provider (entity/person, cd='PRV')
--   22058011-22058013  investigator locators (work addr/work phone/cell)
--   22058020           physician provider (entity/person, cd='PRV')
--   22058021-22058023  physician locators (work addr/work phone/cell)
--   22058030           person-reporter provider (entity/person, cd='PRV')
--   22058031-22058033  reporter-person locators (work addr/work phone/cell)
--   22058040           reporter organization (entity/organization)
--   22058041-22058042  reporter-org locators (work addr/work phone)
--   22058050           hospital organization (entity/organization)
--   22058051-22058052  hospital locators (work addr/work phone)
--   nbs_act_entity_uid is IDENTITY (NOT flood-prone per IDENTITY_REFACTOR_PLAN);
--   let it AUTO-assign and guard on the natural key (act_uid, entity_uid,
--   type_cd) per LESSON 10/11.
--
-- Foundation dependencies (read-only):
--   @superuser_id 10009282 ; TB PHC 22001000 (act/public_health_case,
--   authored in tb_investigation_full_chain.sql).
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;

-- ----- UID allocations (block 22058000-22058999) -----
DECLARE @pat_uid        bigint = 22058000;   -- rich TB patient (PSN/PAT)
DECLARE @pat_pst_home   bigint = 22058001;   -- patient home address (PST,H,H)
DECLARE @pat_pst_bir    bigint = 22058002;   -- patient birth country (PST,BIR,BIR)
DECLARE @pat_tel_home   bigint = 22058003;   -- patient home phone (TELE,H,PH)
DECLARE @pat_tel_work   bigint = 22058004;   -- patient work phone (TELE,WP,PH) + ext
DECLARE @pat_tel_cell   bigint = 22058005;   -- patient cell phone (TELE,*,CP)
DECLARE @pat_tel_email  bigint = 22058006;   -- patient email (TELE,H,NET)

DECLARE @inv_uid        bigint = 22058010;   -- investigator provider (PSN/PRV)
DECLARE @inv_pst        bigint = 22058011;   -- investigator work address (PST,WP,O)
DECLARE @inv_tel_work   bigint = 22058012;   -- investigator work phone (TELE,WP,O) + ext
DECLARE @inv_tel_cell   bigint = 22058013;   -- investigator cell phone (TELE,CP,*)

DECLARE @phys_uid       bigint = 22058020;   -- physician provider (PSN/PRV)
DECLARE @phys_pst       bigint = 22058021;   -- physician work address (PST,WP,O)
DECLARE @phys_tel_work  bigint = 22058022;   -- physician work phone (TELE,WP,O) + ext
DECLARE @phys_tel_cell  bigint = 22058023;   -- physician cell phone (TELE,CP,*)

DECLARE @rpt_prv_uid    bigint = 22058030;   -- person reporter provider (PSN/PRV)
DECLARE @rpt_prv_pst    bigint = 22058031;   -- reporter work address (PST,WP,O)
DECLARE @rpt_prv_tel_w  bigint = 22058032;   -- reporter work phone (TELE,WP,O) + ext
DECLARE @rpt_prv_tel_c  bigint = 22058033;   -- reporter cell phone (TELE,CP,*)

DECLARE @rpt_org_uid    bigint = 22058040;   -- reporter organization (ORG)
DECLARE @rpt_org_pst    bigint = 22058041;   -- reporter org work address (PST,WP,O)
DECLARE @rpt_org_tel    bigint = 22058042;   -- reporter org work phone (TELE,WP,PH) + ext

DECLARE @hosp_org_uid   bigint = 22058050;   -- hospital organization (ORG)
DECLARE @hosp_org_pst   bigint = 22058051;   -- hospital org work address (PST,WP,O)
DECLARE @hosp_org_tel   bigint = 22058052;   -- hospital org work phone (TELE,WP,PH)

-- =====================================================================
-- (1) RICH TB PATIENT  -> D_PATIENT -> PATIENT_* cols.
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
         N'F', '1979-09-22T00:00:00', N'PAT', N'F', N'N', NULL,
         N'2186-5', CAST(GETDATE() AS DATE), @superuser_id, N'PSN22058000GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Priya', N'Anne', N'Ramanathan', N'SR', 1,
         '2026-04-01T00:00:00', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         N'N', @pat_uid, N'Y',
         N'46', N'Y',
         N'M', N'BA', N'291141',
         N'ENG', N'Y', N'6', N'D',
         N'TB RVCT dedicated index patient — Round 5 item C (TB)');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@pat_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'Priya', N'Anne', N'Ramanathan', N'SR', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    -- entity_id (SS).
    INSERT INTO [dbo].[entity_id]
        ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
    VALUES
        (@pat_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'444-55-6666', N'SS', N'Social Security', '2026-04-01T00:00:00');

    -- person_race: Asian root + detail under one category.
    INSERT INTO [dbo].[person_race]
        ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [as_of_date])
    VALUES
        (@pat_uid, N'2028-9', N'2028-9', '2026-04-01T00:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', '2026-04-01T00:00:00'),
        (@pat_uid, N'2040-4', N'2028-9', '2026-04-01T00:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', '2026-04-01T00:00:00');

    -- Locators.
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [street_addr2], [zip_cd], [census_tract], [within_city_limits_ind])
    VALUES
        (@pat_pst_home, '2026-04-01T00:00:00', @superuser_id, N'Atlanta',
         N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'1450 Peachtree Industrial Blvd', N'Unit 12', N'30341', N'1230600', N'Y');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_pst_bir, '2026-04-01T00:00:00', @superuser_id, N'Chennai',
         N'356', CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_tel_home, '2026-04-01T00:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-8000', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tel_work, '2026-04-01T00:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-8001', N'5533',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tel_cell, '2026-04-01T00:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-8002', NULL,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [email_address],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_tel_email, '2026-04-01T00:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'priya.ramanathan@nbs.test',
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@pat_uid, @pat_pst_home, '2026-04-01T00:00:00', @superuser_id, N'H',
         N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'patient home address',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_pst_bir, '2026-04-01T00:00:00', @superuser_id, N'BIR',
         N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'patient birth country',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'BIR', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_home, '2026-04-01T00:00:00', @superuser_id, N'PH',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'patient home phone',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_work, '2026-04-01T00:00:00', @superuser_id, N'PH',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'patient work phone',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_cell, '2026-04-01T00:00:00', @superuser_id, N'CP',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'patient cell phone',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00'),
        (@pat_uid, @pat_tel_email, '2026-04-01T00:00:00', @superuser_id, N'NET',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'patient email',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (2) THREE DEDICATED PROVIDER PERSONS (cd='PRV', self-parented) ->
--     D_PROVIDER -> INVESTIGATOR_*, PHYSICIAN_*/PHYSICIAN_KEY, REPORTER_*.
--     Filters per sp_provider_event: phone_work/email_work need (TELE,O,WP);
--     address (PST,O,WP); cell (TELE,CP,*).
-- =====================================================================
DECLARE @superuser_id2 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = 22058010)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
        (22058010, N'PSN'), (22058020, N'PSN'), (22058030, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id], [cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
         [version_ctrl_nbr], [as_of_date_general],
         [electronic_ind], [person_parent_uid], [edx_ind], [description])
    VALUES
        -- Investigator
        (22058010, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         CAST(GETDATE() AS DATE), @superuser_id2, N'PSN22058010GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Gail', N'R', N'Investigator', N'MS', NULL,
         1, '2026-04-01T00:00:00', N'N', 22058010, N'Y',
         N'TB dedicated investigator'),
        -- Physician
        (22058020, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         CAST(GETDATE() AS DATE), @superuser_id2, N'PSN22058020GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Harold', N'M', N'Physician', N'DR', NULL,
         1, '2026-04-01T00:00:00', N'N', 22058020, N'Y',
         N'TB dedicated physician'),
        -- Person reporter
        (22058030, '2026-04-01T00:00:00', @superuser_id2, N'PRV',
         CAST(GETDATE() AS DATE), @superuser_id2, N'PSN22058030GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Denise', N'K', N'Reporter', N'MS', NULL,
         1, '2026-04-01T00:00:00', N'N', 22058030, N'Y',
         N'TB dedicated person-reporter');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (22058010, 1, '2026-04-01T00:00:00', @superuser_id2, N'Gail', N'R', N'Investigator', N'MS', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (22058020, 1, '2026-04-01T00:00:00', @superuser_id2, N'Harold', N'M', N'Physician', N'DR', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (22058030, 1, '2026-04-01T00:00:00', @superuser_id2, N'Denise', N'K', N'Reporter', N'MS', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    -- Work addresses (PST,O,WP).
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [zip_cd])
    VALUES
        (22058011, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'10 TB Control Program Plaza', N'30303'),
        (22058021, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'20 Pulmonary Clinic Way', N'30303'),
        (22058031, '2026-04-01T00:00:00', @superuser_id2, N'Atlanta', N'840', N'13121',
         CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'30 Reporter Row', N'30303');

    -- Work phones (TELE,O,WP) WITH extension + cell phones (TELE,CP,*).
    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (22058012, '2026-04-01T00:00:00', @superuser_id2, N'1',
         CAST(GETDATE() AS DATE), @superuser_id2, N'404-555-8810', N'1010',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22058013, '2026-04-01T00:00:00', @superuser_id2, N'1',
         CAST(GETDATE() AS DATE), @superuser_id2, N'404-555-8811', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22058022, '2026-04-01T00:00:00', @superuser_id2, N'1',
         CAST(GETDATE() AS DATE), @superuser_id2, N'404-555-8820', N'2020',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22058023, '2026-04-01T00:00:00', @superuser_id2, N'1',
         CAST(GETDATE() AS DATE), @superuser_id2, N'404-555-8821', NULL,
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22058032, '2026-04-01T00:00:00', @superuser_id2, N'1',
         CAST(GETDATE() AS DATE), @superuser_id2, N'404-555-8830', N'3030',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22058033, '2026-04-01T00:00:00', @superuser_id2, N'1',
         CAST(GETDATE() AS DATE), @superuser_id2, N'404-555-8831', NULL,
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        -- investigator
        (22058010, 22058011, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         CAST(GETDATE() AS DATE), @superuser_id2, N'inv work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058010, 22058012, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id2, N'inv work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058010, 22058013, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id2, N'inv cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        -- physician
        (22058020, 22058021, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         CAST(GETDATE() AS DATE), @superuser_id2, N'phys work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058020, 22058022, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id2, N'phys work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058020, 22058023, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id2, N'phys cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        -- reporter
        (22058030, 22058031, '2026-04-01T00:00:00', @superuser_id2, N'O', N'PST',
         CAST(GETDATE() AS DATE), @superuser_id2, N'rpt work addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058030, 22058032, '2026-04-01T00:00:00', @superuser_id2, N'O', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id2, N'rpt work phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058030, 22058033, '2026-04-01T00:00:00', @superuser_id2, N'CP', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id2, N'rpt cell', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (3) TWO DEDICATED ORGANIZATIONS -> D_ORGANIZATION ->
--     REPORTING_SOURCE_NAME + HOSPITAL_NAME/HOSPITAL_KEY.
--     Filters per sp_organization_event: address (PST,WP,O), phone (TELE,WP,PH).
-- =====================================================================
DECLARE @superuser_id3 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[organization] WHERE organization_uid = 22058040)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES
        (22058040, N'ORG'), (22058050, N'ORG');

    INSERT INTO [dbo].[organization]
        ([organization_uid], [add_time], [add_user_id], [description],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [display_nm], [version_ctrl_nbr], [electronic_ind],
         [standard_industry_class_cd], [standard_industry_desc_txt], [edx_ind])
    VALUES
        (22058040, '2026-04-01T00:00:00', @superuser_id3, N'TB dedicated reporting org',
         CAST(GETDATE() AS DATE), @superuser_id3, N'ORG22058040GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'DeKalb County TB Surveillance Lab', 1, N'Y',
         N'621511', N'Medical Laboratories', N'Y'),
        (22058050, '2026-04-01T00:00:00', @superuser_id3, N'TB dedicated admitting hospital',
         CAST(GETDATE() AS DATE), @superuser_id3, N'ORG22058050GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Emory University Hospital TB Unit', 1, N'Y',
         N'622110', N'General Medical and Surgical Hospitals', N'Y');

    INSERT INTO [dbo].[organization_name]
        ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd],
         [record_status_cd], [default_nm_ind])
    VALUES
        (22058040, 1, N'DeKalb County TB Surveillance Lab', N'L', N'ACTIVE', N'Y'),
        (22058050, 1, N'Emory University Hospital TB Unit', N'L', N'ACTIVE', N'Y');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [zip_cd])
    VALUES
        (22058041, '2026-04-01T00:00:00', @superuser_id3, N'Decatur', N'840', N'13089',
         CAST(GETDATE() AS DATE), @superuser_id3, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'41 Surveillance Lab Blvd', N'30030'),
        (22058051, '2026-04-01T00:00:00', @superuser_id3, N'Atlanta', N'840', N'13121',
         CAST(GETDATE() AS DATE), @superuser_id3, N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'1364 Clifton Road NE', N'30322');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (22058042, '2026-04-01T00:00:00', @superuser_id3, N'1',
         CAST(GETDATE() AS DATE), @superuser_id3, N'404-555-8840', N'4040',
         N'ACTIVE', '2026-04-01T00:00:00'),
        (22058052, '2026-04-01T00:00:00', @superuser_id3, N'1',
         CAST(GETDATE() AS DATE), @superuser_id3, N'404-555-8850', N'5050',
         N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (22058040, 22058041, '2026-04-01T00:00:00', @superuser_id3, N'O', N'PST',
         CAST(GETDATE() AS DATE), @superuser_id3, N'rpt org addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058040, 22058042, '2026-04-01T00:00:00', @superuser_id3, N'PH', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id3, N'rpt org phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058050, 22058051, '2026-04-01T00:00:00', @superuser_id3, N'O', N'PST',
         CAST(GETDATE() AS DATE), @superuser_id3, N'hosp addr', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (22058050, 22058052, '2026-04-01T00:00:00', @superuser_id3, N'PH', N'TELE',
         CAST(GETDATE() AS DATE), @superuser_id3, N'hosp phone', N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');
END
GO

-- =====================================================================
-- (4) REPOINT PHC 22001000's PERSON PARTICIPATIONS to the new entities.
--     - Supersede the shared-foundation SubjOfPHC (-> 20000000) with one
--       to the new rich patient 22058000 (allowed: investigation's own
--       link row, not a shared dim).
--     - Add InvestgrOfPHC / PhysicianOfPHC / PerAsReporterOfPHC.
--     subject_class_cd='PSN'; act_class_cd='CASE'. Person participations
--     surface in routine 056's person_participations JSON; the service
--     maps them onto INVESTIGATION/nrt_investigation per
--     ProcessInvestigationDataUtil.
-- =====================================================================
DECLARE @superuser_id4 bigint = 10009282;
DECLARE @tb_phc bigint = 22001000;

-- Supersede the foundation SubjOfPHC for THIS investigation only.
DELETE FROM [dbo].[participation]
WHERE act_uid = @tb_phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 20000000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @tb_phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 22058000)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@tb_phc, 22058000, N'SubjOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id4, CAST(GETDATE() AS DATE), @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Subject of Public Health Case');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @tb_phc AND type_cd = 'InvestgrOfPHC' AND subject_entity_uid = 22058010)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@tb_phc, 22058010, N'InvestgrOfPHC', N'CASE', N'PSN',
     '2026-04-02T00:00:00', '2026-04-02T00:00:00', @superuser_id4, CAST(GETDATE() AS DATE), @superuser_id4,
     N'ACTIVE', '2026-04-02T00:00:00', N'A', '2026-04-02T00:00:00', N'Investigator');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @tb_phc AND type_cd = 'PhysicianOfPHC' AND subject_entity_uid = 22058020)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@tb_phc, 22058020, N'PhysicianOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', @superuser_id4, CAST(GETDATE() AS DATE), @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Physician');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @tb_phc AND type_cd = 'PerAsReporterOfPHC' AND subject_entity_uid = 22058030)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@tb_phc, 22058030, N'PerAsReporterOfPHC', N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id4, CAST(GETDATE() AS DATE), @superuser_id4,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Person as Reporter');
GO

-- =====================================================================
-- (5) ORGANIZATION PARTICIPATIONS for PHC 22001000.
--     OrgAsReporterOfPHC -> organization_id ; HospOfADT -> hospital_uid.
--     subject_class_cd='ORG'.
-- =====================================================================
DECLARE @superuser_id5 bigint = 10009282;
DECLARE @tb_phc5 bigint = 22001000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @tb_phc5 AND type_cd = 'OrgAsReporterOfPHC' AND subject_entity_uid = 22058040)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@tb_phc5, 22058040, N'OrgAsReporterOfPHC', N'CASE', N'ORG',
     '2026-04-01T00:00:00', @superuser_id5, CAST(GETDATE() AS DATE), @superuser_id5,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Organization as Reporter');

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @tb_phc5 AND type_cd = 'HospOfADT' AND subject_entity_uid = 22058050)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@tb_phc5, 22058050, N'HospOfADT', N'CASE', N'ORG',
     '2026-04-01T00:00:00', @superuser_id5, CAST(GETDATE() AS DATE), @superuser_id5,
     N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'Hospital of ADT');
GO

-- =====================================================================
-- (6) nbs_act_entity edges for PHC 22001000 pointing at the NEW dedicated
--     org/hospital/reporter. Routine 056's investigation_act_entity CASE-pivot
--     (056:909-934) computes org_as_reporter_uid / hospital_uid /
--     person_as_reporter_uid as MAX(entity_uid) per type_cd, GROUPED BY
--     act_uid. zz_tb_fact_chain.sql already authored these three type_cds for
--     22001000 pointing at FOUNDATION entities 20000020/20000010 (to set
--     nac_page_case_uid). Because MAX wins and 22058xxx > 20000xxx, these new
--     edges OVERRIDE the foundation ones in the pivot -> the dim keys resolve
--     to our rich entities, while nac_page_case_uid stays 22001000.
--     nbs_act_entity_uid is IDENTITY (NOT flood-prone — IDENTITY_REFACTOR_PLAN);
--     LESSON 10/11: let IDENTITY auto-assign, guard on the natural key
--     (act_uid, entity_uid, type_cd).
-- =====================================================================
DECLARE @superuser_id6 bigint = 10009282;
DECLARE @tb_phc6 bigint = 22001000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @tb_phc6 AND entity_uid = 22058030 AND type_cd = 'PerAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@tb_phc6, 22058030, N'PerAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id6, CAST(GETDATE() AS DATE), @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @tb_phc6 AND entity_uid = 22058040 AND type_cd = 'OrgAsReporterOfPHC')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@tb_phc6, 22058040, N'OrgAsReporterOfPHC', 1,
     '2026-04-01T00:00:00', @superuser_id6, CAST(GETDATE() AS DATE), @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity]
               WHERE act_uid = @tb_phc6 AND entity_uid = 22058050 AND type_cd = 'HospOfADT')
INSERT INTO [dbo].[nbs_act_entity]
    ([act_uid], [entity_uid], [type_cd], [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    (@tb_phc6, 22058050, N'HospOfADT', 1,
     '2026-04-01T00:00:00', @superuser_id6, CAST(GETDATE() AS DATE), @superuser_id6,
     N'ACTIVE', '2026-04-01T00:00:00');
GO

-- =====================================================================
-- (7) CDC RE-TRIGGER: bump public_health_case.last_chg_time so the
--     Debezium/connect chain re-emits PHC 22001000 -> the service re-runs
--     sp_investigation_event and rebuilds nrt_investigation with the new
--     patient_id / investigator_id / physician_id / person_as_reporter_uid /
--     organization_id / hospital_uid. (This is the investigation's OWN row;
--     not a shared dim. No nrt_*/EXEC sp_ here.) zz_tb_fact_chain.sql sorts
--     AFTER this file and also bumps 22001000's last_chg_time — that re-trigger
--     re-emits with ALL participations (this fixture's + its own) present, so
--     the result is the same either way; this bump just guarantees a re-emit
--     even if zz_tb_fact_chain were absent.
-- =====================================================================
UPDATE [dbo].[public_health_case]
SET last_chg_time = '2026-06-04T00:00:03'
WHERE public_health_case_uid = 22001000;
GO
