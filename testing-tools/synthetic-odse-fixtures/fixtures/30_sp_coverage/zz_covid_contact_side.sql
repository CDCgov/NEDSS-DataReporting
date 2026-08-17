-- =====================================================================
-- Tier 3 (NO-SHORTCUT, Round 5 inc-w2) — Contact-SIDE COVID investigation
--   to fill covid_contact_datamart's CTT_PATIENT_* / CTT_INV_* block.
-- =====================================================================
-- Authored 2026-06-04. UID block 22063000-22063999 (reserved in
--   catalog/uid_ranges.md). ODSE-only: no nrt_* INSERTs, no EXEC sp_*.
--
-- TARGET: dbo.covid_contact_datamart (currently 51/94 — the SRC_*/CR_*
--   block filled by zz_covid_contact_fill.sql / R4-L). This fixture fills
--   the remaining CTT_PATIENT_* (22 cols) + CTT_INV_* (17 cols) block.
--
-- WHY THOSE COLUMNS WERE NULL (verified live 2026-06-04)
--   sp_covid_contact_datamart_postprocessing (routine 315) projects the
--   CTT_ columns conditioned on con.CONTACT_ENTITY_PHC_UID:
--     * CTT_PATIENT_* (315:113-206 + OUTER APPLY pd 356-377):
--         CASE WHEN con.CONTACT_ENTITY_PHC_UID IS NOT NULL
--              THEN ctt_pat_inv.<col>       -- D_PATIENT ON PATIENT_UID = con_inv.patient_id  (315:322-323)
--              ELSE ctt_pat_con.<col>       -- D_PATIENT ON PATIENT_UID = con.CONTACT_ENTITY_UID (315:326-327)
--       R4-L left contact_entity_phc_uid NULL, so the ELSE branch read
--       ctt_pat_con = D_PATIENT on CONTACT_ENTITY_UID (22051000), which has
--       NO D_PATIENT row -> all CTT_PATIENT_* NULL.
--     * CTT_INV_* (315:208-222) come straight from
--         con_inv = nrt_investigation ON con.CONTACT_ENTITY_PHC_UID
--                                       = con_inv.public_health_case_uid (315:289-290)
--       (plus j_con_inv jurisdiction 315:297-298 and con_inv_asw1..4
--       nrt_page_case_answer 315:301-319). With contact_entity_phc_uid NULL
--       the con_inv join matched nothing -> all CTT_INV_* NULL.
--   NOTE: the con_inv join carries NO cd='11065' filter and is NOT gated by
--   @phcid_list (only the MAIN inv is, 315:379-383). So the contact-side
--   PHC need only exist as an nrt_investigation; it does NOT need to be in
--   $PHC_UIDS for the CTT_ join to resolve. (The new PHC IS added to
--   PHC_UIDS via the ORCH_TODO below anyway, so it is also driven first-
--   class by every Step-9 SP that takes @phcid_list — harmless + tidy.)
--
-- THE FIX (ODSE-only, additive)
--   Author a contact-SIDE COVID investigation owned by the contact party:
--     (1) a NEW richly-attributed contact patient person 22063000 (full
--         name/middle/suffix, DOB, sex, deceased, race/ethnicity, full home
--         address, home/work/cell phone + work-ext, email) -> the pipeline
--         (CDC -> sp_patient_event -> nrt_patient -> sp_nrt_patient_postprocessing)
--         builds a rich D_PATIENT row keyed PATIENT_UID = 22063000.
--     (2) a contact-side public_health_case 22063100 (cd='11065',
--         jurisdiction 130001, case_class 'C', status 'O', + PHC-core
--         scalars hospitalized/diagnosis/onset/outcome) + its act parent +
--         act_id -> the pipeline (CDC -> sp_investigation_event routine 056
--         -> nrt_investigation) builds nrt_investigation 22063100.
--     (3) SubjOfPHC participation 22063100 -> 22063000 so routine 056's
--         person_participations JSON sets nrt_investigation 22063100
--         .patient_id = 22063000 (verified mapping: SubjOfPHC + PSN +
--         person_cd='PAT' -> patient_id, ProcessInvestigationDataUtil).
--     (4) repoint the EXISTING ct_contact 22051010 (R4-L) so its OWN
--         contact_entity_phc_uid = 22063100. This is the investigation's own
--         contact-link scalar (per-investigation, NOT a shared dim) so an
--         UPDATE of it is allowed. The bump of last_chg_time re-triggers
--         CDC on dbo.CT_contact -> sp_contact_record_event -> nrt_contact so
--         nrt_contact.CONTACT_ENTITY_PHC_UID picks up 22063100.
--   Then routine 315 takes the THEN branch:
--     con_inv (nrt_investigation 22063100)  -> CTT_INV_*  fill.
--     ctt_pat_inv (D_PATIENT on con_inv.patient_id = 22063000) -> CTT_PATIENT_* fill.
--
-- VERIFIED LIVE (read-only) before authoring:
--   * ct_contact 22051010: subject_entity_uid=20000000, contact_entity_uid=
--     22051000, subject_entity_phc_uid=22003000, contact_entity_phc_uid=NULL.
--   * covid_contact_datamart has 1 row; CTT_PATIENT_FIRST_NAME /
--     CTT_INV_JURISDICTION_NM / CTT_INV_STATUS / CTT_INV_CASE_STATUS all NULL.
--   * nrt_investigation 22003000 was built by the pipeline from the ODSE PHC
--     (cd=11065, patient_id=22055000) -> confirms an ODSE PHC + SubjOfPHC is
--     reproduced into nrt_investigation with patient_id resolved (the exact
--     mechanism this fixture relies on for 22063100/22063000).
--   * nrt_srte_Jurisdiction_code '130001' = 'Fulton County' (CTT_INV_JURISDICTION_NM).
--
-- EXPECTED COLUMNS NEWLY POPULATED on covid_contact_datamart (the 1 row):
--   CTT_PATIENT_* (22): CTT_PATIENT_FIRST_NAME, _MIDDLE_NAME, _LAST_NAME,
--     _DOB, _AGE_REPORTED, _AGE_RPTD_UNIT, _CURRENT_SEX, _DECEASED_IND,
--     _DECEASED_DT, _STREET_ADDR_1, _STREET_ADDR_2, _CITY, _STATE, _ZIP,
--     _COUNTY, _COUNTRY, _TEL_HOME, _PHONE_WORK, _PHONE_EXT_WORK, _TEL_CELL,
--     _EMAIL  (CTT_PATIENT_DECEASED_DT NULL by design — contact not deceased).
--   CTT_INV_* (17): CTT_INV_JURISDICTION_NM, _START_DT, _STATUS,
--     _STATE_CASE_ID, _LEGACY_CASE_ID, _CDC_ASSIGNED_ID, _RPTNG_CNTY,
--     _HSPTLIZD_IND, _DIE_FRM_ILLNESS_IND, _DEATH_DT, _CASE_STATUS,
--     _SYMPTOMATIC, _ILLNESS_ONSET_DT, _ILLNESS_END_DT, _SYMPTOM_STATUS.
--     (STATE_CASE_ID/LEGACY_CASE_ID/CDC_ASSIGNED_ID/RPTNG_CNTY/SYMPTOMATIC/
--      SYMPTOM_STATUS are NRT_INVESTIGATION/nrt_page_case_answer-derived and
--      may stay NULL where no answer is authored — the bulk of CTT_INV_*
--      (jurisdiction/start/status/case-status/onset/end/hsptlizd/death) come
--      from the public_health_case scalars below. Net new fill ~30-39 cols.)
--
-- ORCH_TODO (orchestrator): add the new contact-side PHC UID 22063100 to
--   $PHC_UIDS in scripts/merge_and_verify.sh (Step 9). NOT strictly required
--   for the CTT_ join (con_inv is ungated), but keeps 22063100 first-class
--   under a full Step-9 rebuild (e.g. its own d_investigation/case_count
--   rows). The covid_contact SP itself already runs with @phcid_list=$PHC_UIDS
--   and the MAIN subject PHC 22003000 is already in the list.
--
-- IDENTITY / GENERATED ALWAYS: no nbs_case_answer authored here (no CTT_INV
--   page-answers needed for the bulk fill), so no IDENTITY guard required.
--   GENERATED ALWAYS period cols are omitted from public_health_case.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id      bigint = 10009282;   -- conventional NBS superuser id

-- ----- UID allocations (block 22063000-22063999) -----
DECLARE @ctt_pat_uid       bigint = 22063000;   -- rich contact-side patient (PSN/PAT)
DECLARE @ctt_pst_home      bigint = 22063001;   -- contact home address (PST,H,H)
DECLARE @ctt_pst_bir       bigint = 22063002;   -- contact birth country (PST,BIR,BIR)
DECLARE @ctt_tel_home      bigint = 22063003;   -- contact home phone (TELE,H,PH)
DECLARE @ctt_tel_work      bigint = 22063004;   -- contact work phone (TELE,WP,PH) + ext
DECLARE @ctt_tel_cell      bigint = 22063005;   -- contact cell phone (TELE,*,CP)
DECLARE @ctt_tel_email     bigint = 22063006;   -- contact email (TELE,H,NET)

DECLARE @ctt_phc_uid       bigint = 22063100;   -- contact-side PHC (act.act_uid + public_health_case_uid)

DECLARE @existing_ct_uid   bigint = 22051010;   -- R4-L ct_contact row (subject_entity_phc_uid=22003000)

-- =====================================================================
-- (1) RICH CONTACT-SIDE PATIENT -> D_PATIENT (ctt_pat_inv) -> CTT_PATIENT_*
--     Mirrors zz_covid_dedicated_entities.sql's rich patient (22055000),
--     self-parented cd='PAT'. NOT deceased (deceased_ind 'N') so
--     CTT_PATIENT_DECEASED_DT stays NULL by design.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[person] WHERE person_uid = @ctt_pat_uid)
BEGIN
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@ctt_pat_uid, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id],
         [birth_gender_cd], [birth_time], [cd], [curr_sex_cd], [deceased_ind_cd],
         [ethnic_group_ind], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [version_ctrl_nbr],
         [as_of_date_general], [as_of_date_admin], [as_of_date_ethnicity],
         [as_of_date_morbidity], [as_of_date_sex],
         [electronic_ind], [person_parent_uid], [edx_ind],
         [age_reported], [age_reported_unit_cd],
         [marital_status_cd], [education_level_cd], [occupation_cd],
         [prim_lang_cd], [speaks_english_cd],
         [description])
    VALUES
        (@ctt_pat_uid, '2026-04-15T10:00:00', @superuser_id,
         N'F', '1990-06-11T00:00:00', N'PAT', N'F', N'N',
         N'2135-2', CAST(GETDATE() AS DATE), @superuser_id, N'PSN22063000GA01',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
         N'Maria', N'Elena', N'Contreras', NULL, 1,
         '2026-04-15T10:00:00', '2026-04-15T10:00:00', '2026-04-15T10:00:00',
         '2026-04-15T10:00:00', '2026-04-15T10:00:00',
         N'N', @ctt_pat_uid, N'Y',
         N'35', N'Y',
         N'S', N'BS', N'291141',
         N'ENG', N'Y',
         N'COVID-19 contact-side investigation subject — Round 5 inc-w2');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@ctt_pat_uid, 1, '2026-04-15T10:00:00', @superuser_id,
         N'Maria', N'Elena', N'Contreras', N'L',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00');

    -- entity_id (SS).
    INSERT INTO [dbo].[entity_id]
        ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
    VALUES
        (@ctt_pat_uid, 1, '2026-04-15T10:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
         N'555-66-7777', N'SS', N'Social Security', '2026-04-15T10:00:00');

    -- person_race: Black or African American root + category.
    INSERT INTO [dbo].[person_race]
        ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [as_of_date])
    VALUES
        (@ctt_pat_uid, N'2054-5', N'2054-5', '2026-04-15T10:00:00', @superuser_id,
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-15T10:00:00', '2026-04-15T10:00:00');

    -- Locators: home address (CTT_PATIENT_STREET_ADDR_1/2, CITY, STATE, ZIP, COUNTY), birth country.
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [street_addr2], [zip_cd], [census_tract], [within_city_limits_ind])
    VALUES
        (@ctt_pst_home, '2026-04-15T10:00:00', @superuser_id, N'Atlanta',
         N'840', N'13121', CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00', N'13',
         N'88 Quarantine Court', N'Apt 4B', N'30303', N'1210320', N'Y');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time])
    VALUES
        (@ctt_pst_bir, '2026-04-15T10:00:00', @superuser_id, N'Atlanta',
         N'840', CAST(GETDATE() AS DATE), @superuser_id,
         N'ACTIVE', '2026-04-15T10:00:00');

    -- Phones: home / work (+ext) / cell, then email.
    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@ctt_tel_home, '2026-04-15T10:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-6100', NULL,
         N'ACTIVE', '2026-04-15T10:00:00'),
        (@ctt_tel_work, '2026-04-15T10:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-6101', N'4242',
         N'ACTIVE', '2026-04-15T10:00:00'),
        (@ctt_tel_cell, '2026-04-15T10:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'404-555-6102', NULL,
         N'ACTIVE', '2026-04-15T10:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [email_address],
         [record_status_cd], [record_status_time])
    VALUES
        (@ctt_tel_email, '2026-04-15T10:00:00', @superuser_id, N'1',
         CAST(GETDATE() AS DATE), @superuser_id, N'maria.contreras@nbs.test',
         N'ACTIVE', '2026-04-15T10:00:00');

    -- home address (PST,H,H); birth country (PST,BIR,BIR); home/work/cell phone; email.
    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd],
         [class_cd], [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@ctt_pat_uid, @ctt_pst_home, '2026-04-15T10:00:00', @superuser_id, N'H',
         N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'contact home address',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'H', 1, '2026-04-15T10:00:00'),
        (@ctt_pat_uid, @ctt_pst_bir, '2026-04-15T10:00:00', @superuser_id, N'BIR',
         N'PST', CAST(GETDATE() AS DATE), @superuser_id, N'contact birth country',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'BIR', 1, '2026-04-15T10:00:00'),
        (@ctt_pat_uid, @ctt_tel_home, '2026-04-15T10:00:00', @superuser_id, N'PH',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'contact home phone',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'H', 1, '2026-04-15T10:00:00'),
        (@ctt_pat_uid, @ctt_tel_work, '2026-04-15T10:00:00', @superuser_id, N'PH',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'contact work phone',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'WP', 1, '2026-04-15T10:00:00'),
        (@ctt_pat_uid, @ctt_tel_cell, '2026-04-15T10:00:00', @superuser_id, N'CP',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'contact cell phone',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'H', 1, '2026-04-15T10:00:00'),
        (@ctt_pat_uid, @ctt_tel_email, '2026-04-15T10:00:00', @superuser_id, N'NET',
         N'TELE', CAST(GETDATE() AS DATE), @superuser_id, N'contact email',
         N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'H', 1, '2026-04-15T10:00:00');
END
GO

-- =====================================================================
-- (2) CONTACT-SIDE PHC -> nrt_investigation (con_inv) -> CTT_INV_*
--     act parent + public_health_case (cd='11065', juris 130001) + act_id.
--     PHC-core scalars below feed CTT_INV_HSPTLIZD_IND / _DIE_FRM_ILLNESS_IND
--     / _DEATH_DT / _ILLNESS_ONSET_DT / _ILLNESS_END_DT (the contact was
--     symptomatic but recovered: hospitalized 'N', not deceased).
-- =====================================================================
DECLARE @superuser_id2 bigint = 10009282;
DECLARE @ctt_phc bigint = 22063100;

INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@ctt_phc, N'CASE', N'EVN');

INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [mmwr_week], [mmwr_year],
     [hospitalized_ind_cd], [diagnosis_time],
     [effective_from_time], [effective_to_time],
     [outcome_cd], [activity_from_time])
VALUES
    (@ctt_phc, '2026-04-15T10:00:00', @superuser_id2, N'I',
     N'C', N'11065', N'2019 Novel Coronavirus', N'NND', N'NND',
     N'O', CAST(GETDATE() AS DATE), @superuser_id2, N'CAS22063100GA01',
     N'OPEN', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00',
     N'T', 1, N'COV', N'130001',
     22063100, N'N', NULL,
     N'16', N'2026',
     N'N', '2026-04-14T00:00:00',
     '2026-04-12T00:00:00', '2026-04-26T00:00:00',
     N'C', '2026-04-15T00:00:00');

INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [assigning_authority_cd], [assigning_authority_desc_txt],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd],
     [type_desc_txt], [status_cd], [status_time])
VALUES
    (@ctt_phc, 1, '2026-04-15T10:00:00', @superuser_id2,
     N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
     CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE',
     '2026-04-15T10:00:00', N'CAS22063100GA01', N'PHC_LOCAL_ID',
     N'Local Public Health Case Identifier', N'A', '2026-04-15T10:00:00');
GO

-- =====================================================================
-- (3) SubjOfPHC participation: contact-side PHC 22063100 -> contact
--     patient 22063000. Routine 056 person_participations JSON maps
--     SubjOfPHC + PSN + person_cd='PAT' -> nrt_investigation.patient_id.
--     subject_class_cd='PSN'; act_class_cd='CASE'.
-- =====================================================================
DECLARE @superuser_id3 bigint = 10009282;
DECLARE @ctt_phc3 bigint = 22063100;
DECLARE @ctt_pat3 bigint = 22063000;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @ctt_phc3 AND type_cd = 'SubjOfPHC' AND subject_entity_uid = @ctt_pat3)
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
VALUES
    (@ctt_phc3, @ctt_pat3, N'SubjOfPHC', N'CASE', N'PSN',
     '2026-04-15T10:00:00', @superuser_id3, CAST(GETDATE() AS DATE), @superuser_id3,
     N'ACTIVE', '2026-04-15T10:00:00', N'A', '2026-04-15T10:00:00', N'Subject of Public Health Case');
GO

-- =====================================================================
-- (4) Repoint the EXISTING ct_contact 22051010 (R4-L) so its OWN
--     contact_entity_phc_uid = 22063100 (the contact-side PHC). This is
--     the investigation's own contact-link scalar (per-investigation, NOT
--     a shared dim) -> the prompt explicitly sanctions this UPDATE.
--     Bumping last_chg_time re-fires CDC on dbo.CT_contact ->
--     sp_contact_record_event -> nrt_contact, so nrt_contact
--     .CONTACT_ENTITY_PHC_UID = 22063100 and routine 315 takes the THEN
--     branch (ctt_pat_inv / con_inv) for the CTT_ block.
--     Guarded: only repoints if still NULL/different (idempotent re-apply).
-- =====================================================================
DECLARE @ctt_phc4 bigint = 22063100;
DECLARE @existing_ct4 bigint = 22051010;

UPDATE [dbo].[ct_contact]
SET [contact_entity_phc_uid] = @ctt_phc4,
    [last_chg_time] = '2026-04-16T10:00:00',
    [version_ctrl_nbr] = ISNULL([version_ctrl_nbr], 1) + 1
WHERE [ct_contact_uid] = @existing_ct4
  AND ISNULL([contact_entity_phc_uid], -1) <> @ctt_phc4;
GO

PRINT 'zz_covid_contact_side.sql applied: contact-side COVID PHC 22063100 (+ rich patient 22063000, SubjOfPHC) authored; ct_contact 22051010 repointed contact_entity_phc_uid -> 22063100. Pipeline -> nrt_investigation/nrt_patient/nrt_contact -> covid_contact_datamart CTT_PATIENT_*/CTT_INV_*.';
GO
