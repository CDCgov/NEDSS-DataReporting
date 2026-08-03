-- =====================================================================
-- Manual pipeline seed: 5 patients, 5 providers, 5 authorized users
-- =====================================================================
-- PURPOSE
--   This is a hand-run script, NOT an automated JUnit fixture. It is meant
--   to be executed directly against a live/dev NBS_ODSE database so the
--   real CDC/Debezium pipeline in reporting-pipeline-service picks up the
--   inserts and the resulting RDB_MODERN output can be reviewed manually.
--   It is intentionally NOT discovered by DataDrivenFunctionalTests /
--   DataDrivenUnitTests, which only scan testData/functional and
--   testData/unit (non-recursively) for setup.sql+query.sql pairs.
--
-- GOAL: FIELD COVERAGE, NOT RECORD QUANTITY
--   Quantity is not the point -- only 5 of each entity type are created.
--   Instead, each of the 5 patients/providers is deliberately given a
--   DIFFERENT combination of populated columns and child-table row counts
--   (see the per-record header comments below) so that, collectively, the
--   15 records exercise as much of the Person / Auth_user column surface
--   and as many one-to-many child-table shapes (multiple names, multiple
--   races, root+detail race pairs, multiple addresses/phones, absent
--   optional data, inactive-status rows, etc.) as realistically plausible.
--
-- UID ALLOCATION (registered in reporting-pipeline-service/src/test/resources/testData/functional/README.md)
--   Patients:      1000020000 - 1000020099  (20 UIDs reserved per patient)
--   Providers:     1000020100 - 1000020199  (20 UIDs reserved per provider)
--   Auth users:    1000020200 - 1000020299  (10 UIDs reserved per auth user)
--   Investigations: 1000020300 - 1000020304 (1 Act/Public_health_case per patient)
--
-- SCHEMA NOTES
--   Patients and providers are both `Person` rows (Entity supertype,
--   class_cd='PSN'; Person.cd='PAT' or 'PRV'; Person.person_uid =
--   Entity.entity_uid). local_id follows the standard convention:
--     N'PSN' + CONVERT(nvarchar(20), ABS(person_uid)) + N'GA01'
--   Address/phone/email are NOT separate Person_* tables -- they live in
--   Postal_locator / Tele_locator joined via Entity_locator_participation
--   (class_cd='PST'|'TELE', cd/use_cd distinguish the locator subtype).
--   Auth_user is a flat table unrelated to the Entity/Person supertype;
--   auth_user_uid is an IDENTITY column (hence SET IDENTITY_INSERT).
--
-- NOTES -- VERIFIED LIVE AGAINST localhost,3433 (NBS_ODSE / NBS_SRTE) ON 2026-08-02
--   1. Person_ethnic_group.ethnic_group_cd values were checked against the
--      live P_ETHN_GRP codeset in NBS_SRTE.Code_value_general, which only
--      defines '2135-2' (Hispanic or Latino) and '2186-5' (Not Hispanic or
--      Latino) -- NOT the single-letter 'H'/'N' codes an earlier draft of
--      this script (and one existing repo fixture, elrEColi) used. Fixed
--      below to use the verified codes.
--   2. Also verified live: Person_race codes 2106-3/2028-9/2034-7/1002-5/
--      1004-1/2054-5/U (all present in NBS_SRTE Race-related codesets),
--      and Person.ethnic_unk_reason_cd='6'/sex_unk_reason_cd='D' (P_ETHN_
--      UNK_REASON / SEX_UNK_REASON codesets).
--   3. Separately confirmed by grep that sp_patient_event (reporting-
--      pipeline-service/src/main/resources/db/changelog/migrations/v7.13/
--      rdb/routines/054-sp_patient_event-001.sql) reads ethnicity only
--      from Person.ethnic_group_ind -- it does NOT read Person_ethnic_group
--      at all. The Person_ethnic_group rows below are still inserted for
--      schema completeness/field coverage, but don't expect them to
--      surface in the pipeline's ethnicity output; Person.ethnic_group_ind
--      (set on Patients 1 and 5) is the field that actually matters there.
--   4. Auth_user's user_type/user_title/user_department/user_work_email/
--      user_work_phone/user_mobile_phone/master_sec_admin_ind/
--      prog_area_admin_ind/external_org_uid/user_password/user_comments/
--      jurisdiction_derivation_ind columns are captured raw by CDC but are
--      NOT projected by the downstream sp_auth_user_event stored
--      procedure (verified: reporting-pipeline-service/src/main/resources/
--      db/changelog/migrations/v7.13/rdb/routines/067-sp_auth_user_event-001.sql
--      lines 36-49) -- they will not appear in nrt_auth_user/USER_PROFILE,
--      only in the raw CDC payload.
--   5. user_password values below are obvious placeholders, not real
--      credentials -- do not reuse this pattern outside of test/dev data.
--   6. PATIENT INVESTIGATIONS: the 5 patients are each linked to a minimal
--      Act/Public_health_case via a Participation row (type_cd='SubjOfPHC').
--      This is NOT for field-coverage of investigation data -- it exists
--      because the LEGACY MasterEtl.sh SAS pipeline (PatientDimension.sas,
--      which populates RDB.D_PATIENT) only picks up a patient if PERSON is
--      joined to PARTICIPATION on subject_entity_uid (or CT_CONTACT, or a
--      prior ETL_MISSING_RECORD retry entry) -- a standalone Person with no
--      case/event is invisible to it. Providers have no such requirement
--      (ProviderDimension.sas selects directly from PERSON WHERE cd='PRV'),
--      which is why, before this section was added, all 5 providers landed
--      in RDB.D_PROVIDER but none of the 5 patients landed in RDB.D_PATIENT.
--      RDB_MODERN (the CDC/Debezium pipeline) has no such requirement --
--      this section only matters for the legacy MasterEtl.sh path.
--   6. RE-RUNNABLE: last_chg_time/record_status_time/status_time (the
--      "last updated" columns) are set to @now (GETDATE() at execution
--      time), not a fixed literal, so every run reflects the actual wall
--      clock time. add_time/as_of_date* stay fixed at their original
--      2026-08-02 authoring timestamps (they represent creation/business
--      dates, not "last updated"). Because the UIDs are fixed, the script
--      opens with a cleanup block that deletes any rows already present
--      in the reserved UID range before re-inserting, so it can be run
--      repeatedly to refresh the timestamps and re-trigger the CDC
--      pipeline without manual cleanup.
--
-- ARGUMENT: ApplyRandomChanges (sqlcmd scripting variable)
--   Controls whether the OPTIONAL RANDOM CHANGES section at the bottom of
--   this script runs. That section applies random UPDATEs (name, birth
--   date, race, address, contact info -- see that section for details) to
--   the 10 person records (5 patients + 5 providers) this script creates,
--   to simulate a real edit event and exercise the pipeline's UPDATE path
--   rather than only its INSERT path. It does NOT touch Auth_user (not a
--   person) and it requires the person records to already exist -- the
--   section checks for this and no-ops with an error message if they
--   don't (it always runs after the create section above in this script,
--   so in normal use this check will always pass).
--
--   Pass it via sqlcmd's -v flag:
--     sqlcmd -S <server> -U sa -P '<password>' -C -v ApplyRandomChanges=1 \
--       -i seed_patients_providers_authusers.sql
--   Use ApplyRandomChanges=0 (or omit -v entirely) to skip random changes
--   and only (re-)create the baseline records -- this is the default: if
--   the variable isn't supplied, sqlcmd prints a harmless "scripting
--   variable not defined" warning and this script treats that the same
--   as 0. (A `:setvar ApplyRandomChanges 0` default was deliberately NOT
--   used here -- in this sqlcmd version a :setvar unconditionally
--   overwrites a value already supplied via -v, which would make the
--   argument impossible to turn on. Verified empirically before writing
--   this.)
-- =====================================================================

USE [NBS_ODSE];

DECLARE @superuser_id bigint = 10009282;
DECLARE @now datetime = GETDATE();
DECLARE @ApplyRandomChanges bit = CASE WHEN N'$(ApplyRandomChanges)' IN (N'1', N'true', N'True', N'TRUE') THEN 1 ELSE 0 END;

-- ---------------------------------------------------------------------
-- Cleanup (makes this script idempotent/re-runnable): remove any rows
-- from a previous run of this script before re-inserting, in FK-safe
-- order (children before parents). Scoped exactly to the UID range this
-- script owns (1000020000-1000020299), so it cannot touch any other data.
-- ---------------------------------------------------------------------
DELETE FROM [dbo].[Auth_user] WHERE [auth_user_uid] BETWEEN 1000020200 AND 1000020299;
DELETE FROM [dbo].[Participation] WHERE [subject_entity_uid] BETWEEN 1000020000 AND 1000020099;
DELETE FROM [dbo].[Public_health_case] WHERE [public_health_case_uid] BETWEEN 1000020300 AND 1000020304;
DELETE FROM [dbo].[Act] WHERE [act_uid] BETWEEN 1000020300 AND 1000020304;
DELETE FROM [dbo].[Person_ethnic_group] WHERE [person_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Person_race] WHERE [person_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Person_name] WHERE [person_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Entity_locator_participation] WHERE [entity_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Entity_id] WHERE [entity_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Postal_locator] WHERE [postal_locator_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Tele_locator] WHERE [tele_locator_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Person] WHERE [person_uid] BETWEEN 1000020000 AND 1000020299;
DELETE FROM [dbo].[Entity] WHERE [entity_uid] BETWEEN 1000020000 AND 1000020299;

-- ---------------------------------------------------------------------
-- UID declarations
-- ---------------------------------------------------------------------

-- Patients
DECLARE @p1_uid bigint = 1000020000;
DECLARE @p1_postal_home bigint = 1000020001;
DECLARE @p1_postal_birth bigint = 1000020002;
DECLARE @p1_tele_home bigint = 1000020003;
DECLARE @p1_tele_work bigint = 1000020004;
DECLARE @p1_tele_cell bigint = 1000020005;
DECLARE @p1_tele_email bigint = 1000020006;

DECLARE @p2_uid bigint = 1000020020;
DECLARE @p2_postal_home bigint = 1000020021;
DECLARE @p2_tele_home bigint = 1000020022;

DECLARE @p3_uid bigint = 1000020040;
DECLARE @p3_postal_home bigint = 1000020041;
DECLARE @p3_tele_home bigint = 1000020042;
DECLARE @p3_tele_work bigint = 1000020043;
DECLARE @p3_tele_cell bigint = 1000020044;
DECLARE @p3_tele_email bigint = 1000020045;

DECLARE @p4_uid bigint = 1000020060;
DECLARE @p4_tele_home bigint = 1000020061;

DECLARE @p5_uid bigint = 1000020080;
DECLARE @p5_postal_home bigint = 1000020081;
DECLARE @p5_postal_birth bigint = 1000020082;
DECLARE @p5_tele_home bigint = 1000020083;
DECLARE @p5_tele_email bigint = 1000020084;

-- Providers
DECLARE @pr1_uid bigint = 1000020100;
DECLARE @pr1_postal_work bigint = 1000020101;
DECLARE @pr1_tele_work bigint = 1000020102;
DECLARE @pr1_tele_email bigint = 1000020103;

DECLARE @pr2_uid bigint = 1000020120;
DECLARE @pr2_postal_work bigint = 1000020121;
DECLARE @pr2_tele_work bigint = 1000020122;
DECLARE @pr2_tele_cell_active bigint = 1000020123;
DECLARE @pr2_tele_cell_inactive bigint = 1000020124;
DECLARE @pr2_tele_email bigint = 1000020125;

DECLARE @pr3_uid bigint = 1000020140;
DECLARE @pr3_postal_work bigint = 1000020141;
DECLARE @pr3_tele_work bigint = 1000020142;

DECLARE @pr4_uid bigint = 1000020160;
DECLARE @pr4_tele_work bigint = 1000020161;

DECLARE @pr5_uid bigint = 1000020180;
DECLARE @pr5_postal_work bigint = 1000020181;
DECLARE @pr5_postal_home bigint = 1000020182;
DECLARE @pr5_tele_work bigint = 1000020183;
DECLARE @pr5_tele_cell bigint = 1000020184;
DECLARE @pr5_tele_email bigint = 1000020185;

-- Auth users
DECLARE @au1_uid bigint = 1000020200;
DECLARE @au2_uid bigint = 1000020210;
DECLARE @au3_uid bigint = 1000020220;
DECLARE @au4_uid bigint = 1000020230;
DECLARE @au5_uid bigint = 1000020240;

-- Patient investigations (Act/Public_health_case, one per patient -- see
-- header note #6 on why these exist)
DECLARE @inv_p1 bigint = 1000020300;
DECLARE @inv_p2 bigint = 1000020301;
DECLARE @inv_p3 bigint = 1000020302;
DECLARE @inv_p4 bigint = 1000020303;
DECLARE @inv_p5 bigint = 1000020304;

-- =====================================================================
-- PATIENT 1 of 5 -- "flagship": every applicable Person legacy column
-- populated, 2 names (legal + alias), 2 races (simple multi-race, root
-- only), 1 ethnic group, 2 addresses (home + birthplace), 4 contact
-- methods (home/work phone, cell, email), 2 identifications (SSN + DL).
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@p1_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind], [edx_ind],
    [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
    [administrative_gender_cd], [curr_sex_cd], [birth_gender_cd], [birth_time],
    [preferred_gender_cd], [additional_gender_cd],
    [ethnic_group_ind], [ethnicity_group_cd], [ethnic_group_seq_nbr],
    [race_cd], [race_category_cd], [race_seq_nbr],
    [marital_status_cd], [education_level_cd], [occupation_cd], [prim_lang_cd], [speaks_english_cd],
    [mothers_maiden_nm], [multiple_birth_ind], [birth_order_nbr],
    [adults_in_house_nbr], [children_in_house_nbr],
    [ssn], [dl_num], [dl_state_cd], [medicaid_num], [ehars_id],
    [as_of_date_admin], [as_of_date_ethnicity], [as_of_date_general], [as_of_date_morbidity], [as_of_date_sex],
    [description]
) VALUES (
    @p1_uid, N'2026-08-02T09:00:00', @superuser_id, @now, @superuser_id,
    N'PAT', N'PSN' + CONVERT(nvarchar(20), ABS(@p1_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @p1_uid, N'Y', N'Y',
    N'Margaret', N'Ann', N'Alvarez', N'Dr', N'JR',
    N'F', N'F', N'F', N'1978-03-14T00:00:00',
    N'F', N'Additional gender detail',
    N'2186-5', N'N', 1,
    N'2106-3', N'2106-3', 1,
    N'M', N'BD', N'622110', N'ENG', N'Y',
    N'Delgado', N'N', 1,
    2, 1,
    N'123-45-6001', N'GA1000200001', N'13', N'MCD1000200001', N'EHARS1000200001',
    N'2026-08-02T00:00:00', N'2026-08-02T00:00:00', N'2026-08-02T00:00:00', N'2026-08-02T00:00:00', N'2026-08-02T00:00:00',
    N'Flagship fully-attributed patient for pipeline field-coverage seed'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix], [nm_degree], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES
    (@p1_uid, 1, N'2026-08-02T09:00:00', @superuser_id,
     N'Margaret', N'Ann', N'Alvarez', N'Dr', N'JR', N'PHD', N'L',
     N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'),
    (@p1_uid, 2, N'2026-08-02T09:00:00', @superuser_id,
     N'Maggie', NULL, N'Alvarez', NULL, NULL, NULL, N'AL',
     N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00');

INSERT INTO [dbo].[Person_race] (
    [person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
    [record_status_cd], [record_status_time], [as_of_date]
) VALUES
    (@p1_uid, N'2106-3', N'2106-3', N'2026-08-02T09:00:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00'),
    (@p1_uid, N'2028-9', N'2028-9', N'2026-08-02T09:00:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00');

INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd])
VALUES (@p1_uid, N'2186-5', N'Not Hispanic or Latino', N'ACTIVE');

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [street_addr2], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES
    (@p1_postal_home, N'2026-08-02T09:00:00', @superuser_id,
     N'482 Larkspur Ln', NULL, N'Atlanta', N'13', N'30033', N'13121', N'840',
     N'ACTIVE', @now),
    (@p1_postal_birth, NULL, NULL,
     NULL, NULL, N'Atlanta', NULL, NULL, NULL, N'840',
     NULL, NULL);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES
    (@p1_tele_home, N'2026-08-02T09:00:00', @superuser_id, N'404-555-0101', N'ACTIVE', @now),
    (@p1_tele_work, N'2026-08-02T09:00:00', @superuser_id, N'404-555-0102', N'ACTIVE', @now),
    (@p1_tele_cell, N'2026-08-02T09:00:00', @superuser_id, N'404-555-0103', N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd], [record_status_time])
VALUES (@p1_tele_email, N'2026-08-02T09:00:00', @superuser_id, N'margaret.alvarez@example.com', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@p1_uid, @p1_postal_home,  N'H',  N'PST',  N'H',  N'ACTIVE', @now, N'A', 1),
    (@p1_uid, @p1_postal_birth, N'F',  N'PST',  N'BIR', N'ACTIVE', @now, N'A', 1),
    (@p1_uid, @p1_tele_home,    N'PH', N'TELE', N'H',  N'ACTIVE', @now, N'A', 1),
    (@p1_uid, @p1_tele_work,    N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1),
    (@p1_uid, @p1_tele_cell,    N'CP', N'TELE', N'MC', N'ACTIVE', @now, N'A', 1),
    (@p1_uid, @p1_tele_email,   N'NET',N'TELE', N'H',  N'ACTIVE', @now, N'A', 1);

INSERT INTO [dbo].[Entity_id] (
    [entity_uid], [entity_id_seq], [add_time], [add_user_id],
    [type_cd], [type_desc_txt], [root_extension_txt], [assigning_authority_cd], [assigning_authority_id_type],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES
    (@p1_uid, 1, N'2026-08-02T09:00:00', @superuser_id,
     N'SS', N'Social Security', N'123-45-6001', NULL, NULL,
     N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'),
    (@p1_uid, 2, N'2026-08-02T09:00:00', @superuser_id,
     N'DL', N'Driver''s license number', N'GA1000200001', N'GA', N'L',
     N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00');

-- =====================================================================
-- PATIENT 2 of 5 -- "deceased, minimal": no legacy inline demographic
-- columns, 1 legal name, 1 race, 1 address, 1 phone, no identification.
-- Exercises deceased_ind_cd/deceased_time and the sparse-record path.
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@p2_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind],
    [administrative_gender_cd], [curr_sex_cd], [deceased_ind_cd], [deceased_time]
) VALUES (
    @p2_uid, N'2026-08-02T09:05:00', @superuser_id, @now, @superuser_id,
    N'PAT', N'PSN' + CONVERT(nvarchar(20), ABS(@p2_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @p2_uid, N'N',
    N'M', N'M', N'Y', N'2026-07-15T00:00:00'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES (
    @p2_uid, 1, N'2026-08-02T09:05:00', @superuser_id,
    N'Harold', N'Whitmore', N'L',
    N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'
);

INSERT INTO [dbo].[Person_race] (
    [person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
    [record_status_cd], [record_status_time], [as_of_date]
) VALUES (
    @p2_uid, N'2054-5', N'2054-5', N'2026-08-02T09:05:00', @superuser_id,
    N'ACTIVE', @now, N'2026-08-02T00:00:00'
);

INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd])
VALUES (@p2_uid, N'2186-5', N'Not Hispanic or Latino', N'ACTIVE');

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES (
    @p2_postal_home, N'2026-08-02T09:05:00', @superuser_id,
    N'19 Hollow Creek Rd', N'Macon', N'13', N'31201', N'13021', N'840',
    N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES (@p2_tele_home, N'2026-08-02T09:05:00', @superuser_id, N'478-555-0201', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@p2_uid, @p2_postal_home, N'H',  N'PST',  N'H', N'ACTIVE', @now, N'A', 1),
    (@p2_uid, @p2_tele_home,   N'PH', N'TELE', N'H', N'ACTIVE', @now, N'A', 1);

-- =====================================================================
-- PATIENT 3 of 5 -- "multi-contact": partial legacy columns (name+SSN),
-- 2 names (legal + alias), race recorded as unknown ('U'), 1 address,
-- 4 contact methods, 1 identification (medical record number).
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@p3_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind],
    [first_nm], [last_nm], [ssn], [administrative_gender_cd], [curr_sex_cd]
) VALUES (
    @p3_uid, N'2026-08-02T09:10:00', @superuser_id, @now, @superuser_id,
    N'PAT', N'PSN' + CONVERT(nvarchar(20), ABS(@p3_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @p3_uid, N'Y',
    N'Priya', N'Natarajan', N'123-45-6003', N'F', N'F'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES
    (@p3_uid, 1, N'2026-08-02T09:10:00', @superuser_id,
     N'Priya', N'Natarajan', N'L',
     N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'),
    (@p3_uid, 2, N'2026-08-02T09:10:00', @superuser_id,
     N'Pri', N'Nat', N'AL',
     N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00');

INSERT INTO [dbo].[Person_race] (
    [person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
    [record_status_cd], [record_status_time], [as_of_date]
) VALUES (
    @p3_uid, N'U', N'U', N'2026-08-02T09:10:00', @superuser_id,
    N'ACTIVE', @now, N'2026-08-02T00:00:00'
);

INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd])
VALUES (@p3_uid, N'2186-5', N'Not Hispanic or Latino', N'ACTIVE');

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [street_addr2], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES (
    @p3_postal_home, N'2026-08-02T09:10:00', @superuser_id,
    N'77 Redbud Ct', N'Apt 3', N'Savannah', N'13', N'31401', N'13051', N'840',
    N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES
    (@p3_tele_home, N'2026-08-02T09:10:00', @superuser_id, N'912-555-0301', N'ACTIVE', @now),
    (@p3_tele_work, N'2026-08-02T09:10:00', @superuser_id, N'912-555-0302', N'ACTIVE', @now),
    (@p3_tele_cell, N'2026-08-02T09:10:00', @superuser_id, N'912-555-0303', N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd], [record_status_time])
VALUES (@p3_tele_email, N'2026-08-02T09:10:00', @superuser_id, N'priya.natarajan@example.com', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@p3_uid, @p3_postal_home, N'H',  N'PST',  N'H',  N'ACTIVE', @now, N'A', 1),
    (@p3_uid, @p3_tele_home,   N'PH', N'TELE', N'H',  N'ACTIVE', @now, N'A', 1),
    (@p3_uid, @p3_tele_work,   N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1),
    (@p3_uid, @p3_tele_cell,   N'CP', N'TELE', N'MC', N'ACTIVE', @now, N'A', 1),
    (@p3_uid, @p3_tele_email,  N'NET',N'TELE', N'H',  N'ACTIVE', @now, N'A', 1);

INSERT INTO [dbo].[Entity_id] (
    [entity_uid], [entity_id_seq], [add_time], [add_user_id],
    [type_cd], [type_desc_txt], [root_extension_txt],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES (
    @p3_uid, 1, N'2026-08-02T09:10:00', @superuser_id,
    N'MR', N'Medical record number', N'MRN1000020040',
    N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'
);

-- =====================================================================
-- PATIENT 4 of 5 -- "sparse/unknown": no legacy inline demographic
-- columns, no race, no ethnic group, no address, no identification --
-- only the ethnic/sex "unknown reason" codes and a bare phone number.
-- Exercises the absent-optional-data path throughout the pipeline.
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@p4_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind],
    [ethnic_unk_reason_cd], [sex_unk_reason_cd]
) VALUES (
    @p4_uid, N'2026-08-02T09:15:00', @superuser_id, @now, @superuser_id,
    N'PAT', N'PSN' + CONVERT(nvarchar(20), ABS(@p4_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @p4_uid, N'N',
    N'6', N'D'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_suffix], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES (
    @p4_uid, 1, N'2026-08-02T09:15:00', @superuser_id,
    N'Terrence', N'O''Brien', N'JR', N'L',
    N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'
);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES (@p4_tele_home, N'2026-08-02T09:15:00', @superuser_id, N'229-555-0401', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@p4_uid, @p4_tele_home, N'PH', N'TELE', N'H', N'ACTIVE', @now, N'A', 1);

-- =====================================================================
-- PATIENT 5 of 5 -- "heavy multi-race": partial legacy columns
-- (ethnicity/race summary only), double surname (last_nm2), 5 race rows
-- forming two full root+detail pairs plus a lone root (exercises the
-- multi-race root/detail aggregation path), Hispanic ethnicity, 2
-- addresses, 2 contact methods, no identification.
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@p5_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind],
    [ethnic_group_ind], [ethnicity_group_cd], [race_cd], [race_category_cd]
) VALUES (
    @p5_uid, N'2026-08-02T09:20:00', @superuser_id, @now, @superuser_id,
    N'PAT', N'PSN' + CONVERT(nvarchar(20), ABS(@p5_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @p5_uid, N'Y',
    N'2135-2', N'H', N'1002-5', N'1002-5'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [last_nm2], [nm_prefix], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time], [as_of_date]
) VALUES (
    @p5_uid, 1, N'2026-08-02T09:20:00', @superuser_id,
    N'Sofia', N'Nakamura', N'Reyes', N'Ms', N'L',
    N'ACTIVE', @now, N'A', @now, N'2026-08-02T00:00:00'
);

INSERT INTO [dbo].[Person_race] (
    [person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
    [record_status_cd], [record_status_time], [as_of_date]
) VALUES
    -- American Indian or Alaska Native: root + detail
    (@p5_uid, N'1002-5', N'1002-5', N'2026-08-02T09:20:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00'),
    (@p5_uid, N'1004-1', N'1002-5', N'2026-08-02T09:20:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00'),
    -- Asian: root + Chinese detail
    (@p5_uid, N'2028-9', N'2028-9', N'2026-08-02T09:20:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00'),
    (@p5_uid, N'2034-7', N'2028-9', N'2026-08-02T09:20:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00'),
    -- White: lone root, no detail
    (@p5_uid, N'2106-3', N'2106-3', N'2026-08-02T09:20:00', @superuser_id,
     N'ACTIVE', @now, N'2026-08-02T00:00:00');

INSERT INTO [dbo].[Person_ethnic_group] ([person_uid], [ethnic_group_cd], [ethnic_group_desc_txt], [record_status_cd])
VALUES (@p5_uid, N'2135-2', N'Hispanic or Latino', N'ACTIVE');

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES
    (@p5_postal_home, N'2026-08-02T09:20:00', @superuser_id,
     N'340 Cypress Bend', N'Athens', N'13', N'30601', N'13059', N'840',
     N'ACTIVE', @now),
    (@p5_postal_birth, NULL, NULL,
     NULL, N'San Juan', NULL, NULL, NULL, N'630',
     NULL, NULL);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES (@p5_tele_home, N'2026-08-02T09:20:00', @superuser_id, N'706-555-0501', N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd], [record_status_time])
VALUES (@p5_tele_email, N'2026-08-02T09:20:00', @superuser_id, N'sofia.nakamurareyes@example.com', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@p5_uid, @p5_postal_home,  N'H',  N'PST',  N'H',  N'ACTIVE', @now, N'A', 1),
    (@p5_uid, @p5_postal_birth, N'F',  N'PST',  N'BIR', N'ACTIVE', @now, N'A', 1),
    (@p5_uid, @p5_tele_home,    N'PH', N'TELE', N'H',  N'ACTIVE', @now, N'A', 1),
    (@p5_uid, @p5_tele_email,   N'NET',N'TELE', N'H',  N'ACTIVE', @now, N'A', 1);

-- =====================================================================
-- PATIENT INVESTIGATIONS -- one minimal Act/Public_health_case per patient,
-- with a Participation row (type_cd='SubjOfPHC') linking the patient as its
-- subject. Exists so the legacy MasterEtl.sh SAS pipeline picks these
-- patients up into RDB.D_PATIENT -- see header note #6. Values follow the
-- verified pattern from testData/functional/casesBmirdGeneric/
-- 020-createBmirdCaseInvestigation/setup.sql (condition 11723 =
-- Streptococcus pneumoniae, invasive disease; jurisdiction 130006;
-- prog_area BMIRD).
-- =====================================================================

INSERT INTO [dbo].[Act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@inv_p1, N'CASE', N'EVN'),
    (@inv_p2, N'CASE', N'EVN'),
    (@inv_p3, N'CASE', N'EVN'),
    (@inv_p4, N'CASE', N'EVN'),
    (@inv_p5, N'CASE', N'EVN');

INSERT INTO [dbo].[Public_health_case] (
    [public_health_case_uid], [activity_from_time], [add_time], [add_user_id],
    [case_class_cd], [case_type_cd], [cd], [cd_desc_txt],
    [investigation_status_cd], [jurisdiction_cd], [last_chg_time], [last_chg_user_id],
    [local_id], [prog_area_cd], [record_status_cd], [record_status_time],
    [rpt_source_cd], [status_cd], [shared_ind], [version_ctrl_nbr]
) VALUES
    (@inv_p1, N'2026-08-02T09:30:00', N'2026-08-02T09:30:00', @superuser_id,
     N'P', N'I', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)',
     N'O', N'130006', @now, @superuser_id,
     N'CAS' + CONVERT(nvarchar(20), ABS(@inv_p1)) + N'GA01', N'BMIRD', N'ACTIVE', @now,
     N'RE', N'A', N'T', 1),
    (@inv_p2, N'2026-08-02T09:35:00', N'2026-08-02T09:35:00', @superuser_id,
     N'P', N'I', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)',
     N'O', N'130006', @now, @superuser_id,
     N'CAS' + CONVERT(nvarchar(20), ABS(@inv_p2)) + N'GA01', N'BMIRD', N'ACTIVE', @now,
     N'RE', N'A', N'T', 1),
    (@inv_p3, N'2026-08-02T09:40:00', N'2026-08-02T09:40:00', @superuser_id,
     N'P', N'I', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)',
     N'O', N'130006', @now, @superuser_id,
     N'CAS' + CONVERT(nvarchar(20), ABS(@inv_p3)) + N'GA01', N'BMIRD', N'ACTIVE', @now,
     N'RE', N'A', N'T', 1),
    (@inv_p4, N'2026-08-02T09:45:00', N'2026-08-02T09:45:00', @superuser_id,
     N'P', N'I', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)',
     N'O', N'130006', @now, @superuser_id,
     N'CAS' + CONVERT(nvarchar(20), ABS(@inv_p4)) + N'GA01', N'BMIRD', N'ACTIVE', @now,
     N'RE', N'A', N'T', 1),
    (@inv_p5, N'2026-08-02T09:50:00', N'2026-08-02T09:50:00', @superuser_id,
     N'P', N'I', N'11723', N'Streptococcus pneumoniae, invasive disease (IPD)',
     N'O', N'130006', @now, @superuser_id,
     N'CAS' + CONVERT(nvarchar(20), ABS(@inv_p5)) + N'GA01', N'BMIRD', N'ACTIVE', @now,
     N'RE', N'A', N'T', 1);

INSERT INTO [dbo].[Participation] (
    [subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [from_time],
    [record_status_cd], [record_status_time], [status_cd], [status_time],
    [subject_class_cd], [type_desc_txt]
) VALUES
    (@p1_uid, @inv_p1, N'SubjOfPHC', N'CASE', N'2026-08-02T09:30:00', N'ACTIVE', @now, N'A', @now, N'PSN', N'Subject Of Public Health Case'),
    (@p2_uid, @inv_p2, N'SubjOfPHC', N'CASE', N'2026-08-02T09:35:00', N'ACTIVE', @now, N'A', @now, N'PSN', N'Subject Of Public Health Case'),
    (@p3_uid, @inv_p3, N'SubjOfPHC', N'CASE', N'2026-08-02T09:40:00', N'ACTIVE', @now, N'A', @now, N'PSN', N'Subject Of Public Health Case'),
    (@p4_uid, @inv_p4, N'SubjOfPHC', N'CASE', N'2026-08-02T09:45:00', N'ACTIVE', @now, N'A', @now, N'PSN', N'Subject Of Public Health Case'),
    (@p5_uid, @inv_p5, N'SubjOfPHC', N'CASE', N'2026-08-02T09:50:00', N'ACTIVE', @now, N'A', @now, N'PSN', N'Subject Of Public Health Case');

-- =====================================================================
-- PROVIDER 1 of 5 -- "baseline happy path": partial legacy columns
-- (name only), 1 legal name, 1 work address, work phone + email, 1 NPI.
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@pr1_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind],
    [first_nm], [last_nm]
) VALUES (
    @pr1_uid, N'2026-08-02T10:00:00', @superuser_id, @now, @superuser_id,
    N'PRV', N'PSN' + CONVERT(nvarchar(20), ABS(@pr1_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @pr1_uid, N'Y',
    N'Elena', N'Torres'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_degree], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time]
) VALUES (
    @pr1_uid, 1, N'2026-08-02T10:00:00', @superuser_id,
    N'Elena', N'Torres', N'MD', N'L',
    N'ACTIVE', @now, N'A', @now);

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [street_addr2], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES (
    @pr1_postal_work, N'2026-08-02T10:00:00', @superuser_id,
    N'555 Provider Ave', N'Suite 100', N'Atlanta', N'13', N'30308', N'13121', N'840',
    N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES (@pr1_tele_work, N'2026-08-02T10:00:00', @superuser_id, N'404-555-0610', N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd], [record_status_time])
VALUES (@pr1_tele_email, N'2026-08-02T10:00:00', @superuser_id, N'elena.torres@statelab.org', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@pr1_uid, @pr1_postal_work, N'O',  N'PST',  N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr1_uid, @pr1_tele_work,   N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr1_uid, @pr1_tele_email,  N'O',  N'TELE', N'WP', N'ACTIVE', @now, N'A', 1);

INSERT INTO [dbo].[Entity_id] (
    [entity_uid], [entity_id_seq], [add_time], [type_cd], [root_extension_txt], [assigning_authority_cd],
    [record_status_cd], [record_status_time], [status_cd]
) VALUES (
    @pr1_uid, 1, N'2026-08-02T10:00:00', N'NPI', N'1000200100', N'CMS',
    N'ACTIVE', @now, N'A'
);

-- =====================================================================
-- PROVIDER 2 of 5 -- "active/inactive cell": no legacy inline columns,
-- exercises an INACTIVE Entity_locator_participation row (an active
-- cell phone plus a second, inactive one) alongside work phone/email.
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@pr2_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind]
) VALUES (
    @pr2_uid, N'2026-08-02T10:05:00', @superuser_id, @now, @superuser_id,
    N'PRV', N'PSN' + CONVERT(nvarchar(20), ABS(@pr2_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @pr2_uid, N'Y'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_degree], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time]
) VALUES (
    @pr2_uid, 1, N'2026-08-02T10:05:00', @superuser_id,
    N'Marcus', N'Bell', N'MD', N'L',
    N'ACTIVE', @now, N'A', @now);

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES (
    @pr2_postal_work, N'2026-08-02T10:05:00', @superuser_id,
    N'100 Test Blvd', N'Atlanta', N'13', N'30301', N'13121', N'840',
    N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES
    (@pr2_tele_work,          N'2026-08-02T10:05:00', @superuser_id, N'404-555-0620', N'ACTIVE', @now),
    (@pr2_tele_cell_active,   N'2026-08-02T10:05:00', @superuser_id, N'404-555-0621', N'ACTIVE', @now),
    (@pr2_tele_cell_inactive, N'2026-08-02T10:05:00', @superuser_id, N'404-555-0622', N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd], [record_status_time])
VALUES (@pr2_tele_email, N'2026-08-02T10:05:00', @superuser_id, N'marcus.bell@statelab.org', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@pr2_uid, @pr2_postal_work,      N'O',  N'PST',  N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr2_uid, @pr2_tele_work,        N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr2_uid, @pr2_tele_cell_active, N'CP', N'TELE', N'MC', N'ACTIVE', @now, N'A', 1),
    -- deliberately INACTIVE: proves a real, tested "filtered locator" edge case (see unit/providerEvent)
    (@pr2_uid, @pr2_tele_cell_inactive, N'CP', N'TELE', N'MC', N'INACTIVE', @now, N'I', 1),
    (@pr2_uid, @pr2_tele_email,       N'O',  N'TELE', N'WP', N'ACTIVE', @now, N'A', 1);

INSERT INTO [dbo].[Entity_id] (
    [entity_uid], [entity_id_seq], [add_time], [type_cd], [root_extension_txt], [assigning_authority_cd],
    [record_status_cd], [record_status_time], [status_cd]
) VALUES (
    @pr2_uid, 1, N'2026-08-02T10:05:00', N'NPI', N'1000200120', N'CMS',
    N'ACTIVE', @now, N'A'
);

-- =====================================================================
-- PROVIDER 3 of 5 -- "multi-ID": 1 legal name (DO suffix), 1 work
-- address, 1 work phone, 2 identifications (NPI + DL).
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@pr3_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind]
) VALUES (
    @pr3_uid, N'2026-08-02T10:10:00', @superuser_id, @now, @superuser_id,
    N'PRV', N'PSN' + CONVERT(nvarchar(20), ABS(@pr3_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @pr3_uid, N'Y'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_suffix], [nm_degree], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time]
) VALUES (
    @pr3_uid, 1, N'2026-08-02T10:10:00', @superuser_id,
    N'Renee', N'Okafor', N'DO', N'DO', N'L',
    N'ACTIVE', @now, N'A', @now);

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES (
    @pr3_postal_work, N'2026-08-02T10:10:00', @superuser_id,
    N'88 Wellness Pkwy', N'Macon', N'13', N'31210', N'13021', N'840',
    N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES (@pr3_tele_work, N'2026-08-02T10:10:00', @superuser_id, N'478-555-0630', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@pr3_uid, @pr3_postal_work, N'O',  N'PST',  N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr3_uid, @pr3_tele_work,   N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1);

INSERT INTO [dbo].[Entity_id] (
    [entity_uid], [entity_id_seq], [add_time], [type_cd], [root_extension_txt], [assigning_authority_cd],
    [record_status_cd], [record_status_time], [status_cd]
) VALUES
    (@pr3_uid, 1, N'2026-08-02T10:10:00', N'NPI', N'1000200140', N'CMS',
     N'ACTIVE', @now, N'A'),
    (@pr3_uid, 2, N'2026-08-02T10:10:00', N'DL', N'GA1000200140', N'GA',
     N'ACTIVE', @now, N'A');

-- =====================================================================
-- PROVIDER 4 of 5 -- "inactive/sparse": Person.record_status_cd/status_cd
-- set to INACTIVE/I (negative-path coverage), minimal name, no address,
-- 1 work phone, no identification.
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@pr4_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind]
) VALUES (
    @pr4_uid, N'2026-08-02T10:15:00', @superuser_id, @now, @superuser_id,
    N'PRV', N'PSN' + CONVERT(nvarchar(20), ABS(@pr4_uid)) + N'GA01', N'INACTIVE', @now, N'I', @now,
    1, @pr4_uid, N'Y'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [last_nm], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time]
) VALUES (
    @pr4_uid, 1, N'2026-08-02T10:15:00', @superuser_id,
    N'Sam', N'Iverson', N'L',
    N'ACTIVE', @now, N'A', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES (@pr4_tele_work, N'2026-08-02T10:15:00', @superuser_id, N'229-555-0640', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@pr4_uid, @pr4_tele_work, N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1);

-- =====================================================================
-- PROVIDER 5 of 5 -- "flagship max": legacy inline columns fully
-- populated, 1 legal name (prefix+suffix+degree), 2 addresses
-- (work+home), 3 contact methods, 2 identifications (NPI + DL).
-- =====================================================================

INSERT INTO [dbo].[Entity] ([entity_uid], [class_cd]) VALUES (@pr5_uid, N'PSN');

INSERT INTO [dbo].[Person] (
    [person_uid], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [cd], [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
    [version_ctrl_nbr], [person_parent_uid], [electronic_ind],
    [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
    [administrative_gender_cd], [curr_sex_cd], [occupation_cd], [prim_lang_cd], [marital_status_cd],
    [education_level_cd], [description]
) VALUES (
    @pr5_uid, N'2026-08-02T10:20:00', @superuser_id, @now, @superuser_id,
    N'PRV', N'PSN' + CONVERT(nvarchar(20), ABS(@pr5_uid)) + N'GA01', N'ACTIVE', @now, N'A', @now,
    1, @pr5_uid, N'Y',
    N'Priyanka', N'Rao', N'Desai', N'Dr', N'MD',
    N'F', N'F', N'621111', N'ENG', N'M',
    N'MD', N'Flagship fully-attributed provider for pipeline field-coverage seed'
);

INSERT INTO [dbo].[Person_name] (
    [person_uid], [person_name_seq], [add_time], [add_user_id],
    [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix], [nm_degree], [nm_use_cd],
    [record_status_cd], [record_status_time], [status_cd], [status_time]
) VALUES (
    @pr5_uid, 1, N'2026-08-02T10:20:00', @superuser_id,
    N'Priyanka', N'Rao', N'Desai', N'Dr', N'MD', N'MD', N'L',
    N'ACTIVE', @now, N'A', @now);

INSERT INTO [dbo].[Postal_locator] (
    [postal_locator_uid], [add_time], [add_user_id],
    [street_addr1], [street_addr2], [city_desc_txt], [state_cd], [zip_cd], [cnty_cd], [cntry_cd],
    [record_status_cd], [record_status_time]
) VALUES
    (@pr5_postal_work, N'2026-08-02T10:20:00', @superuser_id,
     N'42 Clinic Row', N'Bldg B', N'Savannah', N'13', N'31404', N'13051', N'840',
     N'ACTIVE', @now),
    (@pr5_postal_home, N'2026-08-02T10:20:00', @superuser_id,
     N'9 Magnolia Trace', NULL, N'Savannah', N'13', N'31406', N'13051', N'840',
     N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [phone_nbr_txt], [record_status_cd], [record_status_time])
VALUES
    (@pr5_tele_work, N'2026-08-02T10:20:00', @superuser_id, N'912-555-0650', N'ACTIVE', @now),
    (@pr5_tele_cell, N'2026-08-02T10:20:00', @superuser_id, N'912-555-0651', N'ACTIVE', @now);

INSERT INTO [dbo].[Tele_locator] ([tele_locator_uid], [add_time], [add_user_id], [email_address], [record_status_cd], [record_status_time])
VALUES (@pr5_tele_email, N'2026-08-02T10:20:00', @superuser_id, N'priyanka.desai@statelab.org', N'ACTIVE', @now);

INSERT INTO [dbo].[Entity_locator_participation] (
    [entity_uid], [locator_uid], [cd], [class_cd], [use_cd],
    [record_status_cd], [record_status_time], [status_cd], [version_ctrl_nbr]
) VALUES
    (@pr5_uid, @pr5_postal_work, N'O',  N'PST',  N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr5_uid, @pr5_postal_home, N'H',  N'PST',  N'H',  N'ACTIVE', @now, N'A', 1),
    (@pr5_uid, @pr5_tele_work,   N'PH', N'TELE', N'WP', N'ACTIVE', @now, N'A', 1),
    (@pr5_uid, @pr5_tele_cell,   N'CP', N'TELE', N'MC', N'ACTIVE', @now, N'A', 1),
    (@pr5_uid, @pr5_tele_email,  N'O',  N'TELE', N'WP', N'ACTIVE', @now, N'A', 1);

INSERT INTO [dbo].[Entity_id] (
    [entity_uid], [entity_id_seq], [add_time], [type_cd], [root_extension_txt], [assigning_authority_cd],
    [record_status_cd], [record_status_time], [status_cd]
) VALUES
    (@pr5_uid, 1, N'2026-08-02T10:20:00', N'NPI', N'1000200180', N'CMS',
     N'ACTIVE', @now, N'A'),
    (@pr5_uid, 2, N'2026-08-02T10:20:00', N'DL', N'GA1000200180', N'GA',
     N'ACTIVE', @now, N'A');

-- =====================================================================
-- AUTHORIZED USERS (5) -- Auth_user is a flat table, not linked to the
-- Entity/Person supertype. auth_user_uid is an IDENTITY column, so
-- SET IDENTITY_INSERT is required (mirrors functional/authUserDirectWrite).
-- Collectively these 5 rows populate every optional Auth_user column at
-- least once, exercise both a linked and unlinked provider_uid, both
-- record_status_cd values, and a nedss_entry_id that deliberately
-- differs from auth_user_uid (an edge case no existing fixture covers).
-- =====================================================================

SET IDENTITY_INSERT [dbo].[Auth_user] ON;

INSERT INTO [dbo].[Auth_user] (
    [auth_user_uid], [user_id], [user_type], [user_title], [user_department],
    [user_first_nm], [user_last_nm], [user_work_email], [user_work_phone], [user_mobile_phone],
    [master_sec_admin_ind], [prog_area_admin_ind], [nedss_entry_id], [external_org_uid],
    [user_password], [user_comments], [jurisdiction_derivation_ind], [provider_uid],
    [add_user_id], [last_chg_user_id], [add_time], [last_chg_time],
    [record_status_cd], [record_status_time]
) VALUES
    -- AU1: fully-attributed, linked to Provider 1, security-admin flag set
    (@au1_uid, N'alice.wong', N'Internal', N'Epidemiologist', N'Communicable Disease',
     N'Alice', N'Wong', N'alice.wong@example.gov', N'404-555-0110', N'404-555-0111',
     N'Y', NULL, @au1_uid, NULL,
     NULL, NULL, N'Y', @pr1_uid,
     @superuser_id, @superuser_id, N'2026-08-02T11:00:00.000', @now,
     N'ACTIVE', @now),
    -- AU2: minimal (mirrors the existing authUserDirectWrite baseline), no provider link
    (@au2_uid, N'bob.jones', NULL, NULL, NULL,
     N'Bob', N'Jones', NULL, NULL, NULL,
     NULL, NULL, @au2_uid, NULL,
     NULL, NULL, NULL, NULL,
     @superuser_id, @superuser_id, N'2026-08-02T11:05:00.000', @now,
     N'ACTIVE', @now),
    -- AU3: linked to Provider 5, program-area admin, external org + password/comments populated
    (@au3_uid, N'carla.mendez', N'Internal', N'Program Coordinator', N'Surveillance',
     N'Carla', N'Mendez', NULL, NULL, NULL,
     NULL, N'Y', @au3_uid, 10003019,
     N'PLACEHOLDER-TEST-ONLY', N'Seeded for pipeline field-coverage manual review', NULL, @pr5_uid,
     @superuser_id, @superuser_id, N'2026-08-02T11:10:00.000', @now,
     N'ACTIVE', @now),
    -- AU4: INACTIVE record, no provider link (negative-path coverage)
    (@au4_uid, N'dana.kim', NULL, NULL, NULL,
     N'Dana', N'Kim', NULL, NULL, NULL,
     NULL, NULL, @au4_uid, NULL,
     NULL, NULL, N'N', NULL,
     @superuser_id, @superuser_id, N'2026-08-02T11:15:00.000', @now,
     N'INACTIVE', @now),
    -- AU5: linked to Provider 3, fully-attributed. nedss_entry_id deliberately != auth_user_uid
    (@au5_uid, N'evan.brooks', N'Internal', N'Program Coordinator', N'Vaccine Preventable Disease',
     N'Evan', N'Brooks', N'evan.brooks@example.gov', N'404-555-0120', N'404-555-0121',
     N'N', N'N', 1000020299, NULL,
     N'PLACEHOLDER-TEST-ONLY', N'nedss_entry_id intentionally differs from auth_user_uid for coverage', NULL, @pr3_uid,
     @superuser_id, @superuser_id, N'2026-08-02T11:20:00.000', @now,
     N'ACTIVE', @now);

SET IDENTITY_INSERT [dbo].[Auth_user] OFF;

-- =====================================================================
-- OPTIONAL RANDOM CHANGES -- gated by $(ApplyRandomChanges), see the
-- ARGUMENT note in the header. Applies random UPDATEs to the 10 person
-- records created above (patients + providers only, not Auth_user) to
-- simulate a real edit event: name, birth date, race, address, and
-- contact info are each independently randomized per row using
-- CHECKSUM(NEWID()), so re-running with the flag on produces different
-- changes each time. Requires the person records to already exist --
-- guarded by an explicit count check below.
-- =====================================================================

IF @ApplyRandomChanges = 1
BEGIN
    DECLARE @PersonUids TABLE (person_uid bigint PRIMARY KEY);
    INSERT INTO @PersonUids (person_uid) VALUES
        (@p1_uid), (@p2_uid), (@p3_uid), (@p4_uid), (@p5_uid),
        (@pr1_uid), (@pr2_uid), (@pr3_uid), (@pr4_uid), (@pr5_uid);

    DECLARE @ExpectedPersonCount int = 10;
    DECLARE @ActualPersonCount int = (
        SELECT COUNT(*) FROM [dbo].[Person] p
        JOIN @PersonUids u ON u.person_uid = p.person_uid
    );

    IF @ActualPersonCount <> @ExpectedPersonCount
    BEGIN
        RAISERROR(N'ApplyRandomChanges=1 was requested, but only %d of the expected %d person records exist. The create section above (which always runs first in this script) must have failed for some records; check for errors before this point. Skipping random changes.', 16, 1, @ActualPersonCount, @ExpectedPersonCount);
    END
    ELSE
    BEGIN
        PRINT N'ApplyRandomChanges=1: applying random changes to the 10 person records...';

        -- 1. NAME -- 50% chance per person, independently, to replace
        --    first_nm and/or last_nm on their legal (person_name_seq=1) name.
        UPDATE pn
        SET
            [first_nm] = CASE WHEN r.change_first = 1 THEN r.new_first_nm ELSE pn.[first_nm] END,
            [last_nm]  = CASE WHEN r.change_last  = 1 THEN r.new_last_nm  ELSE pn.[last_nm]  END,
            [last_chg_time] = @now
        FROM [dbo].[Person_name] pn
        JOIN @PersonUids u ON u.person_uid = pn.[person_uid]
        CROSS APPLY (
            SELECT
                CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 1 THEN 1 ELSE 0 END AS change_first,
                CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 1 THEN 1 ELSE 0 END AS change_last,
                (SELECT v FROM (VALUES (0,N'Jordan'),(1,N'Taylor'),(2,N'Morgan'),(3,N'Casey'),
                                        (4,N'Avery'),(5,N'Riley'),(6,N'Quinn'),(7,N'Skyler')) AS t(i,v)
                 WHERE t.i = ABS(CHECKSUM(NEWID())) % 8) AS new_first_nm,
                (SELECT v FROM (VALUES (0,N'Reed'),(1,N'Foster'),(2,N'Nguyen'),(3,N'Patel'),
                                        (4,N'Osei'),(5,N'Silva'),(6,N'Kowalski'),(7,N'Haddad')) AS t(i,v)
                 WHERE t.i = ABS(CHECKSUM(NEWID())) % 8) AS new_last_nm
        ) r
        WHERE pn.[person_name_seq] = 1;
        PRINT CONCAT(N'  Person_name rows evaluated for name change: ', @@ROWCOUNT);

        -- 2. BIRTH DATE -- 50% chance per person to shift birth_time by a
        --    random +/-10 year offset (assigns one first if it was NULL).
        --    Also unconditionally touches Person's own last_chg_time/
        --    record_status_time/status_time/version_ctrl_nbr for all 10,
        --    since Person is the only person-related table CDC actually
        --    watches directly (see NOTES #3 above) -- this guarantees the
        --    pipeline reprocesses every one of these 10 records on this
        --    run, even for the ones where the other random gates below
        --    don't fire.
        UPDATE p
        SET
            [birth_time] = CASE WHEN r.change_birth = 1
                THEN DATEADD(DAY, r.day_offset, ISNULL(p.[birth_time], CAST(N'1985-01-01' AS datetime)))
                ELSE p.[birth_time] END,
            [last_chg_time] = @now,
            [record_status_time] = @now,
            [status_time] = @now,
            [version_ctrl_nbr] = ISNULL(p.[version_ctrl_nbr], 0) + 1
        FROM [dbo].[Person] p
        JOIN @PersonUids u ON u.person_uid = p.[person_uid]
        CROSS APPLY (
            SELECT
                CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 1 THEN 1 ELSE 0 END AS change_birth,
                (ABS(CHECKSUM(NEWID())) % 7300) - 3650 AS day_offset
        ) r;
        PRINT CONCAT(N'  Person rows touched (birth date +/- CDC trigger): ', @@ROWCOUNT);

        -- 3. RACE -- only for persons with EXACTLY ONE existing Person_race
        --    row (race_cd is part of the primary key, so reassigning it on
        --    a person who already has multiple race rows risks a duplicate-
        --    key violation if the randomly chosen code collides with one of
        --    their other rows; single-race persons have no such risk).
        --    ~50% chance to reassign to a different verified race code.
        ;WITH SingleRacePerson AS (
            SELECT pr.person_uid
            FROM [dbo].[Person_race] pr
            JOIN @PersonUids u ON u.person_uid = pr.person_uid
            GROUP BY pr.person_uid
            HAVING COUNT(*) = 1
        )
        UPDATE pr
        SET
            [race_cd] = CASE WHEN r.change = 1 THEN r.new_code ELSE pr.[race_cd] END,
            [race_category_cd] = CASE WHEN r.change = 1 THEN r.new_code ELSE pr.[race_category_cd] END,
            [record_status_time] = @now
        FROM [dbo].[Person_race] pr
        JOIN SingleRacePerson s ON s.person_uid = pr.person_uid
        CROSS APPLY (
            SELECT
                CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 1 THEN 1 ELSE 0 END AS change,
                (SELECT v FROM (VALUES (0,N'2106-3'),(1,N'2028-9'),(2,N'2054-5'),(3,N'1002-5'),(4,N'U')) AS t(i,v)
                 WHERE t.i = ABS(CHECKSUM(NEWID())) % 5) AS new_code
        ) r;
        PRINT CONCAT(N'  Person_race rows evaluated for reassignment (single-race persons only): ', @@ROWCOUNT);

        -- 4. ADDRESS -- for every ACTIVE postal locator belonging to one of
        --    the 10 persons (excludes the sparse/NULL birthplace-only rows,
        --    which never got an ACTIVE status), 50% chance to replace
        --    street/city/zip with a different value.
        UPDATE pl
        SET
            [street_addr1] = CASE WHEN r.change = 1 THEN r.new_addr ELSE pl.[street_addr1] END,
            [city_desc_txt] = CASE WHEN r.change = 1 THEN r.new_city ELSE pl.[city_desc_txt] END,
            [zip_cd] = CASE WHEN r.change = 1 THEN r.new_zip ELSE pl.[zip_cd] END,
            [record_status_time] = @now
        FROM [dbo].[Postal_locator] pl
        JOIN [dbo].[Entity_locator_participation] elp
            ON elp.[locator_uid] = pl.[postal_locator_uid] AND elp.[class_cd] = N'PST'
        JOIN @PersonUids u ON u.person_uid = elp.[entity_uid]
        CROSS APPLY (
            SELECT
                CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 1 THEN 1 ELSE 0 END AS change,
                (SELECT v FROM (VALUES (0,N'118 Willow Bend'),(1,N'27 Chestnut Way'),(2,N'860 Magnolia Ct'),
                                        (3,N'44 Sunrise Trl'),(4,N'509 Ridgeview Dr')) AS t(i,v)
                 WHERE t.i = ABS(CHECKSUM(NEWID())) % 5) AS new_addr,
                (SELECT v FROM (VALUES (0,N'Augusta'),(1,N'Columbus'),(2,N'Roswell'),
                                        (3,N'Marietta'),(4,N'Albany')) AS t(i,v)
                 WHERE t.i = ABS(CHECKSUM(NEWID())) % 5) AS new_city,
                (SELECT v FROM (VALUES (0,N'30901'),(1,N'31901'),(2,N'30075'),
                                        (3,N'30060'),(4,N'31701')) AS t(i,v)
                 WHERE t.i = ABS(CHECKSUM(NEWID())) % 5) AS new_zip
        ) r
        WHERE pl.[record_status_cd] = N'ACTIVE';
        PRINT CONCAT(N'  Postal_locator rows evaluated for address change: ', @@ROWCOUNT);

        -- 5. CONTACT INFO -- for every ACTIVE tele locator (phone or email)
        --    belonging to one of the 10 persons, 50% chance to replace the
        --    phone number or email address. Deliberately excludes the
        --    INACTIVE cell phone on Provider 2 (its Entity_locator_
        --    participation row has record_status_cd='INACTIVE') so this
        --    doesn't overwrite that intentional filtered-locator test case.
        UPDATE tl
        SET
            [phone_nbr_txt] = CASE WHEN tl.[phone_nbr_txt] IS NOT NULL AND r.change = 1
                THEN r.new_phone ELSE tl.[phone_nbr_txt] END,
            [email_address] = CASE WHEN tl.[email_address] IS NOT NULL AND r.change = 1
                THEN r.new_email ELSE tl.[email_address] END,
            [record_status_time] = @now
        FROM [dbo].[Tele_locator] tl
        JOIN [dbo].[Entity_locator_participation] elp
            ON elp.[locator_uid] = tl.[tele_locator_uid] AND elp.[class_cd] = N'TELE'
        JOIN @PersonUids u ON u.person_uid = elp.[entity_uid]
        CROSS APPLY (
            SELECT
                CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 1 THEN 1 ELSE 0 END AS change,
                N'404-555-' + RIGHT(N'0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS nvarchar(4)), 4) AS new_phone,
                N'updated.' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS nvarchar(10)) + N'@example.com' AS new_email
        ) r
        WHERE elp.[record_status_cd] = N'ACTIVE'
          AND tl.[record_status_cd] = N'ACTIVE';
        PRINT CONCAT(N'  Tele_locator rows evaluated for contact info change: ', @@ROWCOUNT);

        PRINT N'ApplyRandomChanges=1: done.';
    END
END
ELSE
BEGIN
    PRINT N'ApplyRandomChanges is not enabled (pass -v ApplyRandomChanges=1 to sqlcmd to turn it on); skipping random changes.';
END
