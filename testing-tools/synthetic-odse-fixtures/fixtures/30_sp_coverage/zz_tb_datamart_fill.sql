-- =====================================================================
-- zz_tb_datamart_fill.sql  (Round 4, R4-K, no-shortcut, ODSE-only)
-- =====================================================================
-- TARGET: raise dbo.tb_datamart (228/318) and dbo.tb_hiv_datamart
--         (232/322) toward full by authoring a SECOND, richly-attributed
--         TB RVCT investigation whose dimensional/measure columns are the
--         ~90 columns the existing TB PHC 22001000 leaves NULL.
--
-- WHY A NEW INVESTIGATION (not enriching 22001000)
--   Coverage is measured per-COLUMN as "any non-NULL value across all
--   rows" (scripts/coverage_summary.sh: `SUM(CASE WHEN col IS NOT NULL...)
--   > 0`). The single existing tb_datamart/tb_hiv row (PHC 22001000)
--   leaves ~90 columns NULL because:
--     (a) its patient link is the SPARSE foundation patient 20000000
--         (D_PATIENT: no SSN / middle name / suffix / within-city /
--         Asian-Nat.Hi. race breakdown / phone ext) — and the LOOP hard
--         rule forbids UPDATE-ing the shared D_PATIENT dim;
--     (b) it has NO InvestgrOfPHC / PhysicianOfPHC participation, so
--         nrt_investigation.investigator_id / physician_id are NULL and
--         F_TB_PAM resolves PROVIDER_KEY / PHYSICIAN_KEY to the
--         COALESCE(...,1) sentinel -> INVESTIGATOR_* / PHYSICIAN_* NULL;
--     (c) its public_health_case carries few of the rich investigation
--         fields (no hospitalized / diagnosis / illness-onset / day-care
--         / transmission / detection / deceased / mmwr / imported-* etc.);
--     (d) it has no Confirmation_method rows (CONFIRMATION_METHOD_* /
--         CONFIRMATION_DATE NULL);
--     (e) its d_topic answers carry a SINGLE distinct decoded value per
--         group (e.g. MOVE_CNTY all '13121'), so the 255 datamart SP's
--         ROW_NUMBER-over-DISTINCT-VALUE pivot yields only the _1 column
--         (e.g. MOVE_CNTY_2 / _3, OUT_OF_CNTRY_1/3, MOVE_CNTRY_1/3,
--         DISEASE_SITE_3, MOVE_STATE_2/3, MOVED_WHERE_2/3, GT_12_REAS_2/3,
--         HC_PROV_TY_2/3, ADDL_RISK_3, SMR_EXAM_TY_2 stay NULL);
--     (f) three single D_TB_PAM measure cols (PATIENT_BIRTH_COUNTRY,
--         INIT_REGIMEN_PA_SALICYLIC_ACID, FINAL_SUSCEPT_RIFAMPIN) have no
--         answer on 22001000.
--   Because all NULL columns are ROW-level (not table-structural), a
--   second TB investigation that populates them in its own row lifts the
--   whole-table column count for BOTH tb_datamart and tb_hiv_datamart
--   (both are built FROM dbo.F_TB_PAM by routines 255 / 260 and share the
--   same upstream D_TB_PAM + INVESTIGATION + D_PATIENT joins).
--
-- HOW THE REAL PIPELINE TURNS THIS INTO COVERAGE (no-shortcut)
--   Everything below is ODSE only. The reporting-pipeline-service then:
--     1. sp_investigation_event (056): reads public_health_case +
--        participation (person_participations JSON: type_cd +
--        subject_class_cd='PSN' + person_cd 'PAT'/'PRV') + nbs_act_entity
--        -> writes nrt_investigation with patient_id=20020010,
--        investigator_id=20010010, physician_id=20000010,
--        person_as_reporter_uid=20010010, org_as_reporter_uid /
--        hospital_uid=20030010, nac_page_case_uid=22050000, plus all the
--        rich phc.* fields; also emits investigation_case_answer (from
--        nbs_case_answer JOIN nbs_question/nbs_ui_metadata filtered
--        investigation_form_cd IN ('INV_FORM_RVCT','INV_FORM_VAR') AND
--        cc.condition_cd = phc.cd) and investigation_confirmation_method
--        (from dbo.Confirmation_method).
--     2. CDC mirrors nbs_case_answer -> the page-builder writes
--        nrt_page_case_answer (datamart_column_nm, code_set_group_id,
--        question_identifier, seq_nbr from nbs_case_answer.seq_nbr).
--     3. The service page-builder cache fires sp_nrt_d_tb_pam (147) + the
--        12 d_topic SPs (145/146/156/160/170/175/180/185/190/195/200) for
--        the RVCT answers -> D_TB_PAM + D_DISEASE_SITE / D_ADDL_RISK /
--        D_MOVE_* / D_OUT_OF_CNTRY / D_MOVED_WHERE / D_SMR_EXAM_TY /
--        D_GT_12_REAS / D_HC_PROV_TY_3 / D_TB_HIV (+ their _GROUP dims).
--     4. Step 9: sp_f_tb_pam_postprocessing (206) builds F_TB_PAM (key =
--        nac_page_case_uid=22050000; real PROVIDER/PHYSICIAN/ORG keys),
--        then sp_tb_datamart_postprocessing (255) + the tb_hiv variant
--        (260) write the second tb_datamart / tb_hiv_datamart row.
--
-- DISTINCT-VALUE STRATEGY FOR THE _1/_2/_3 REPEATING COLUMNS
--   The 255 SP pivots each group dim with
--     ROW_NUMBER() OVER (PARTITION BY <GROUP_KEY> ORDER BY value)
--   over the DISTINCT decoded VALUE (CODE_SHORT_DESC_TXT, or ANSWER_TXT
--   when the codeset has no rows). So we author THREE DISTINCT codes per
--   repeating d_topic question (seq_nbr 1/2/3), choosing codes whose
--   decoded descriptions sort to ranks 1/2/3, to light up _1, _2 and _3.
--
-- ENTITIES REUSED (read-only; real ODSE entities that already flow through
--   the pipeline to populated D_* dims — verified live 2026-06-03):
--   20020010  "Variant Patient" (person cd='PAT', self-parent) -> rich
--             D_PATIENT (middle name 'Marie', suffix 'Jr.', within-city
--             'Y', Asian race breakdown, work phone ext, general comments)
--             => SubjOfPHC subject. Fills PATIENT_* / RACE_ASIAN_* /
--             PATIENT_WITHIN_CITY_LIMITS / PATIENT_MIDDLE_NAME /
--             PATIENT_NAME_SUFFIX / PATIENT_GENERAL_COMMENTS / age-calc.
--   20010010  "Variant Provider" (person cd='PRV', self-parent) -> rich
--             D_PROVIDER (first 'Variant', last 'Provider', phone) =>
--             InvestgrOfPHC (investigator). Fills INVESTIGATOR_*.
--             Also PerAsReporterOfPHC (REPORTER_* via D_PROVIDER).
--   20000010  "Foundation Provider" (cd='PRV') -> D_PROVIDER (name+phone)
--             => PhysicianOfPHC. Fills PHYSICIAN_*.
--   20030010  "Variant Hospital" -> D_ORGANIZATION (name) =>
--             OrgAsReporterOfPHC + HospOfADT. Fills REPORTING_SOURCE_NAME
--             + HOSPITAL_NAME.
--   10009282  superuser id.
--
-- UID BLOCK (this fixture): 22050000-22050999
--   22050000  act.act_uid + public_health_case.public_health_case_uid
--             + act_id + every nbs_case_answer.act_uid + Confirmation_method
--   22050001  case_management.case_management_uid (IDENTITY_INSERT)
--   nbs_act_entity.nbs_act_entity_uid 22050500-22050502 (IDENTITY_INSERT)
--   nbs_case_answer rows: AUTO-IDENTITY (no hardcoded UID — see ROOT CAUSE
--     note at the answer block; hardcoding collided with the auto-IDENTITY
--     range that earlier fixtures consume).
--
-- IDEMPOTENT: every block guarded by IF NOT EXISTS on its first UID.
-- ADDITIVE: only NEW UID-block rows + the new PHC's own last_chg_time
--   bump. NO UPDATE of any shared dim (D_PATIENT / D_PROVIDER /
--   D_ORGANIZATION / F_*_PAM / USER_PROFILE). NO nrt_* INSERT. NO
--   EXEC sp_*. NO liquibase / seed / SRTE edit. GENERATED ALWAYS period
--   cols omitted (none of the ODSE tables touched here carry them).
--
-- ORCH_TODO (REQUIRED — same pattern as 22043000/22046000/22047000):
--   Add 22050000 to PHC_UIDS in scripts/merge_and_verify.sh so Step 9
--   (sp_f_tb_pam_postprocessing 206, sp_tb_datamart_postprocessing 255,
--   sp_tb_hiv_datamart_postprocessing 260) and the service page-builder
--   process the new TB investigation.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @tb_phc_uid   bigint = 22050000;   -- act_uid + public_health_case_uid
DECLARE @case_mgmt_uid bigint = 22050001;
DECLARE @patient_uid  bigint = 20020010;   -- rich "Variant Patient"
DECLARE @investigator_uid bigint = 20010010;  -- rich "Variant Provider"
DECLARE @physician_uid    bigint = 20000010;  -- "Foundation Provider"
DECLARE @org_uid          bigint = 20030010;  -- rich "Variant Hospital"

-- =====================================================================
-- ODSE: act parent + public_health_case (rich INVESTIGATION fields) + act_id
-- TB-specific codes mirror tb_investigation_full_chain.sql:
--   cd='10220' Tuberculosis, prog_area_cd='TB',
--   investigation_form_cd resolved by condition_code (INV_FORM_RVCT),
--   case_class_cd 'C', investigation_status_cd 'O', jurisdiction '130001'.
-- The rich phc.* fields drive the still-NULL INVESTIGATION columns:
--   hospitalized_ind_cd/admin/discharge/duration, diagnosis_time,
--   pat_age_at_onset(_unit), day_care_ind_cd, food_handler_ind_cd,
--   transmission_mode_cd, disease_imported_cd + imported_*,
--   detection_method_cd, deceased_time (INVESTIGATION_DEATH_DATE),
--   investigator_assigned_time, rpt_to_county_time,
--   rpt_form_cmplt_time (DATE_REPORTED), rpt_to_state_time
--   (DATE_SUBMITTED), rpt_source_cd, mmwr_week/year, pregnant_ind_cd,
--   and die_frm_this_illness_ind = fn_get_value_by_cd_codeset(outcome_cd,
--   'INV145') -> outcome_cd 'Y' (proven-good codes mirror the Tier-1 v2
--   investigation 20050010: transmission_mode_cd 'B', disease_imported_cd
--   'IND', detection_method_cd 'AS', rpt_source_cd 'PP').
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @tb_phc_uid)
BEGIN
    INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
        (@tb_phc_uid, N'CASE', N'EVN');

    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
         [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
         [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [pregnant_ind_cd], [day_care_ind_cd],
         [food_handler_ind_cd], [hospitalized_ind_cd], [outbreak_ind], [outbreak_name],
         [outcome_cd], [transmission_mode_cd], [disease_imported_cd],
         [pat_age_at_onset], [pat_age_at_onset_unit_cd], [detection_method_cd],
         [priority_cd], [curr_process_state_cd],
         [investigator_assigned_time], [diagnosis_time],
         [hospitalized_admin_time], [hospitalized_discharge_time], [hospitalized_duration_amt],
         [imported_country_cd], [imported_state_cd], [imported_city_desc_txt],
         [imported_county_cd], [deceased_time],
         [rpt_form_cmplt_time], [rpt_to_county_time], [rpt_to_state_time],
         [rpt_source_cd], [rpt_source_cd_desc_txt], [rpt_cnty_cd],
         [mmwr_week], [mmwr_year], [txt])
    VALUES
        (@tb_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'I',
         N'C', N'10220', N'Tuberculosis', N'NND', N'NND',
         N'O', CAST(GETDATE() AS DATE), @superuser_id, N'CAS22050000GA01',
         N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'T', 1, N'TB', N'130001',
         22050000, N'N', N'N',
         N'N', N'Y', N'N', NULL,
         N'Y', N'B', N'IND',
         N'52', N'Y', N'AS',
         N'HIGH', N'OPEN-NEW',
         '2026-04-02T00:00:00', '2026-04-03T00:00:00',
         '2026-04-03T00:00:00', '2026-04-12T00:00:00', 9,
         N'840', N'13', N'Atlanta',
         N'13121', '2026-04-11T00:00:00',
         '2026-04-05T00:00:00', '2026-04-06T00:00:00', '2026-04-07T00:00:00',
         N'PP', N'Private Physician Office', N'13121',
         N'15', N'2026',
         N'TB R4-K dimensional-tail investigation — second populated TB case');

    INSERT INTO [dbo].[act_id]
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd],
         [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@tb_phc_uid, 1, '2026-04-01T00:00:00', @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE',
         '2026-04-01T00:00:00', N'CAS22050000GA01', N'PHC_LOCAL_ID',
         N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid], [public_health_case_uid], [status_900],
         [field_record_number], [surv_assigned_date],
         [surv_closed_date], [case_closed_date])
    VALUES
        (@case_mgmt_uid, @tb_phc_uid, N'C',
         N'FRN-TB-R4K-01', '2026-04-02T00:00:00',
         '2026-04-30T00:00:00', '2026-04-30T00:00:00');
    SET IDENTITY_INSERT [dbo].[case_management] OFF;
END
GO

-- =====================================================================
-- ODSE: person participations.
--   SubjOfPHC  -> patient 20020010 (rich D_PATIENT) : patient_id
--   InvestgrOfPHC -> provider 20010010 (rich D_PROVIDER) : investigator_id
--   PhysicianOfPHC -> provider 20000010 : physician_id
--   PerAsReporterOfPHC -> provider 20010010 : person_as_reporter_uid
-- The event SP's person_participations JSON joins participation to person
-- on person.person_uid = person_parent_uid of the subject, then the Java
-- util keys on (type_cd, subject_class_cd='PSN', person_cd 'PAT'/'PRV').
-- All four subjects are real PSN entities with cd='PAT'/'PRV' + self
-- person_parent_uid (verified live).
-- =====================================================================
DECLARE @phc bigint = 22050000;
DECLARE @user2 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @phc AND type_cd = 'SubjOfPHC' AND subject_entity_uid = 20020010)
BEGIN
    INSERT INTO [dbo].[participation]
        (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id,
         last_chg_time, last_chg_user_id, record_status_cd, record_status_time,
         status_cd, status_time, subject_class_cd, type_desc_txt)
    VALUES
        (20020010, @phc, 'SubjOfPHC',     'CASE', '2026-04-01', @user2,
         CAST(GETDATE() AS DATE), @user2, 'ACTIVE', '2026-04-01', 'A', '2026-04-01', 'PSN',
         'Subject of Public Health Case'),
        (20010010, @phc, 'InvestgrOfPHC', 'CASE', '2026-04-01', @user2,
         CAST(GETDATE() AS DATE), @user2, 'ACTIVE', '2026-04-01', 'A', '2026-04-01', 'PSN',
         'Investigator of Public Health Case'),
        (20000010, @phc, 'PhysicianOfPHC','CASE', '2026-04-01', @user2,
         CAST(GETDATE() AS DATE), @user2, 'ACTIVE', '2026-04-01', 'A', '2026-04-01', 'PSN',
         'Physician of Public Health Case'),
        (20010010, @phc, 'PerAsReporterOfPHC','CASE', '2026-04-01', @user2,
         CAST(GETDATE() AS DATE), @user2, 'ACTIVE', '2026-04-01', 'A', '2026-04-01', 'PSN',
         'Person as Reporter of Public Health Case');
END
GO

-- =====================================================================
-- ODSE: nbs_act_entity — drives nac_page_case_uid (=> F_TB_PAM key) AND
--   org_as_reporter_uid / hospital_uid (=> REPORTING_SOURCE_NAME /
--   HOSPITAL_NAME via D_ORGANIZATION 20030010). Mirrors the proven
--   zz_tb_fact_chain.sql pattern, but pointed at the rich Variant Hospital.
--   nbs_act_entity_uid is IDENTITY; pin our reserved UIDs.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_act_entity] WHERE nbs_act_entity_uid = 22050500)
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;
    INSERT INTO [dbo].[nbs_act_entity]
        ([nbs_act_entity_uid], [act_uid], [add_time], [add_user_id],
         [entity_uid], [entity_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [type_cd])
    VALUES
        (22050500, 22050000, '2026-04-01T00:00:00', 10009282,
         20030010, 1, CAST(GETDATE() AS DATE), 10009282,
         N'ACTIVE', '2026-04-01T00:00:00', N'OrgAsReporterOfPHC'),
        (22050501, 22050000, '2026-04-01T00:00:00', 10009282,
         20030010, 1, CAST(GETDATE() AS DATE), 10009282,
         N'ACTIVE', '2026-04-01T00:00:00', N'HospOfADT'),
        (22050502, 22050000, '2026-04-01T00:00:00', 10009282,
         20010010, 1, CAST(GETDATE() AS DATE), 10009282,
         N'ACTIVE', '2026-04-01T00:00:00', N'PerAsReporterOfPHC');
    SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
END
GO

-- =====================================================================
-- ODSE: Confirmation_method rows -> CONFIRMATION_METHOD_1/2/_ALL +
--   CONFIRMATION_DATE (255 SP STRING_AGG over distinct
--   CONFIRMATION_METHOD_DESC ordered). Codes from SRTE PHC_CONF_M:
--   'LD' Laboratory confirmed, 'CI' Case/Outbreak Investigation
--   (two DISTINCT descriptions -> _1 and _2). confirmation_method_time
--   feeds CONFIRMATION_DATE.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Confirmation_method]
               WHERE public_health_case_uid = 22050000 AND confirmation_method_cd = 'LD')
BEGIN
    INSERT INTO [dbo].[Confirmation_method]
        ([public_health_case_uid], [confirmation_method_cd],
         [confirmation_method_desc_txt], [confirmation_method_time])
    VALUES
        (22050000, N'LD', N'Laboratory confirmed',                 '2026-04-04T00:00:00'),
        (22050000, N'CI', N'Case/Outbreak Investigation',          '2026-04-04T00:00:00');
END
GO

-- =====================================================================
-- ODSE: nbs_case_answer — the RVCT TUB* / d_topic answers.
--   nbs_case_answer_uid is IDENTITY; we let it AUTO-assign (do NOT pin —
--   see the ROOT CAUSE note below for why hardcoding collided & no-op'd).
--   The event SP resolves datamart_column_nm + code_set_group_id from
--   nbs_question (by nbs_question_uid) and question_identifier from
--   nbs_ui_metadata; we supply act_uid, nbs_question_uid, answer_txt,
--   seq_nbr only. answer_group_seq_nbr left default (these are PAM /
--   d_topic single-block answers, not D_INVESTIGATION_REPEAT blocks).
--
--   THREE SETS:
--   (A) Single D_TB_PAM measure cols still NULL on 22001000:
--         1327 TUB276 PATIENT_BIRTH_COUNTRY          (4260 PHVS_TB_BIRTH_CNTRY) 'CAN'
--         1000 TUB180 INIT_REGIMEN_PA_SALICYLIC_ACID (4150 YNU)                 'Y'
--         1004 TUB245 FINAL_SUSCEPT_RIFAMPIN         (4170 PHVS_TB_SUSCEPT)     'S'
--       Plus HIV_STATUS (1273 TUB154) '260385009' so the tb_hiv_datamart
--       row carries an HIV status (D_TB_HIV via routine 160).
--   (B) Repeating d_topic questions — 3 DISTINCT codes each (seq 1/2/3)
--       so the 255 ROW_NUMBER-over-distinct-VALUE pivot fills _1/_2/_3:
--         1079 TUB119 DISEASE_SITE  (2470 PHVS_TB_ADDL_SITE)
--         1230 TUB167 ADDL_RISK     (2600 PHVS_TB_RISK_FACTORS)
--         1256 TUB225 MOVED_WHERE   (4180 PHVS_TB_DIS_ACQ_JUR)
--         1055 TUB228 MOVE_CNTY     (560  COUNTY_CCD — empty codeset ->
--                                    decoded VALUE falls back to ANSWER_TXT)
--         1248 TUB229 MOVE_STATE    (3920 STATE_CCD)
--         1243 TUB230 MOVE_CNTRY    (4260 PHVS_TB_BIRTH_CNTRY)
--         1318 TUB235 GT_12_REAS    (2520 PHVS_TB_EXTEND_REAS)
--         1071 TUB237 HC_PROV_TY    (2530 PHVS_TB_HC_PRAC_TY)
--         1080 TUB114 OUT_OF_CNTRY  (4260 PHVS_TB_BIRTH_CNTRY)
--       NOTE: 1174 TUB129 SMR_EXAM_TY (PHVS_TB_MICRO_EX_TY) has only TWO
--       valid codes in the seed (Pathology/Cytology, Smear) -> SMR_EXAM_TY_3
--       is unreachable from real codes (documented ceiling, not authored).
--   All codes verified valid in nrt_srte_code_value_general 2026-06-03.
-- =====================================================================
-- =====================================================================
-- ROOT CAUSE OF THE PRIOR NO-LAND (fixed below):
--   This block ORIGINALLY used SET IDENTITY_INSERT + hardcoded
--   nbs_case_answer_uid = 22050100..22050196, guarded by
--   IF NOT EXISTS (...nbs_case_answer_uid = 22050100). But
--   zz_page_answers_datamart_routing.sql (applies alphabetically BEFORE
--   this file) inserts ~1376 nbs_case_answer rows via AUTO-IDENTITY (no
--   IDENTITY_INSERT), which pushed the IDENTITY counter (IDENT_CURRENT
--   = 22051042) straight through the 22050100..22050999 range. So by the
--   time this block ran, UID 22050100 was ALREADY occupied (by an auto-
--   IDENTITY row for act 22004000), the guard saw it as "exists", and the
--   ENTIRE answer INSERT was SKIPPED -> 22050000 got ZERO answers ->
--   no D_TB_PAM row (routine 147 keys D_TB_PAM off page answers) ->
--   no F_TB_PAM row (255/206 INNER JOIN D_TB_PAM ON TB_PAM_UID) ->
--   no tb_datamart / tb_hiv_datamart 2nd row.
--
--   FIX: do NOT hardcode nbs_case_answer_uid at all. Let the IDENTITY
--   column auto-assign (collision-proof) and guard on act_uid=22050000
--   instead of a single hardcoded UID. The pipeline keys page answers on
--   (act_uid, nbs_question_uid, seq_nbr) -- the surrogate UID value is
--   irrelevant downstream. (Reserved block 22052000-22052999 is therefore
--   NOT needed for these answers -- IDENTITY owns the value.)
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = 22050000 AND nbs_question_uid = 1327)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    -- (A) single measure cols
    (22050000, '2026-04-01T00:00:00', 10009282, N'CAN',       1327, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB276 PATIENT_BIRTH_COUNTRY
    (22050000, '2026-04-01T00:00:00', 10009282, N'Y',         1000, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB180 INIT_REGIMEN_PA_SALICYLIC_ACID
    (22050000, '2026-04-01T00:00:00', 10009282, N'S',         1004, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB245 FINAL_SUSCEPT_RIFAMPIN
    (22050000, '2026-04-01T00:00:00', 10009282, N'260385009', 1273, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB154 HIV_STATUS Negative

    -- (B) repeating d_topic — 3 distinct codes each (seq 1/2/3)
    -- DISEASE_SITE (TUB119, 1079): Accessory sinus / Adrenal gland / Pulmonary
    (22050000, '2026-04-01T00:00:00', 10009282, N'120228005', 1079, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'23451007',  1079, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'39607008',  1079, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- ADDL_RISK (TUB167, 1230): Contact of Infectious / Contact of MDR / Diabetes Mellitus
    (22050000, '2026-04-01T00:00:00', 10009282, N'PHC687',    1230, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'PHC686',    1230, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'73211009',  1230, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- MOVED_WHERE (TUB225, 1256): In state out-of-jur / Out of state / Out of the U.S.
    (22050000, '2026-04-01T00:00:00', 10009282, N'PHC245',    1256, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'PHC246',    1256, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'C1512888',  1256, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- MOVE_CNTY (TUB228, 1055): COUNTY_CCD empty -> VALUE = ANSWER_TXT; 3 distinct strings
    (22050000, '2026-04-01T00:00:00', 10009282, N'13089',     1055, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'13121',     1055, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'13135',     1055, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- MOVE_STATE (TUB229, 1248): Alabama / Alaska / Arizona
    (22050000, '2026-04-01T00:00:00', 10009282, N'01',        1248, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'02',        1248, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'04',        1248, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- MOVE_CNTRY (TUB230, 1243): Canada / France / United Kingdom
    (22050000, '2026-04-01T00:00:00', 10009282, N'CAN',       1243, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'FRA',       1243, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'GBR',       1243, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- GT_12_REAS (TUB235, 1318): Adverse Drug Reaction / Failure / Non-adherence
    (22050000, '2026-04-01T00:00:00', 10009282, N'62014003',  1318, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'76797004',  1318, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'258143003', 1318, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- HC_PROV_TY (TUB237, 1071): Inpatient Care Only / Institutional-Correctional / Local-State HD
    (22050000, '2026-04-01T00:00:00', 10009282, N'394656005', 1071, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'PHC665',    1071, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'PHC663',    1071, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- OUT_OF_CNTRY (TUB114, 1080): Canada / France / United Kingdom
    (22050000, '2026-04-01T00:00:00', 10009282, N'CAN',       1080, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'FRA',       1080, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
    (22050000, '2026-04-01T00:00:00', 10009282, N'GBR',       1080, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
    -- SMR_EXAM_TY (TUB129, 1174): only 2 distinct codes exist -> _1/_2 (no _3)
    (22050000, '2026-04-01T00:00:00', 10009282, N'108257001', 1174, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
    (22050000, '2026-04-01T00:00:00', 10009282, N'386147002', 1174, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2);
END
GO

-- ---------------------------------------------------------------------
-- Re-trigger CDC -> service so sp_investigation_event (re)processes the
-- new TB PHC AFTER its participations / nbs_act_entity / answers /
-- confirmation rows exist. public_health_case is the CDC-tracked table
-- (capture instance dbo_Public_health_case) the reporting-pipeline-service
-- keys investigation reprocessing on; same bump pattern as
-- zz_tb_fact_chain.sql / zz_page_answers_datamart_routing.sql.
-- ---------------------------------------------------------------------
UPDATE [dbo].[public_health_case]
   SET last_chg_time = GETDATE()
 WHERE public_health_case_uid = 22050000;
GO
