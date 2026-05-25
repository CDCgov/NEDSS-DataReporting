-- =====================================================================
-- Tier 3 ENRICHMENT — MORBIDITY_REPORT_DATAMART column expansion
-- =====================================================================
-- Lifts MORBIDITY_REPORT_DATAMART populated-column count by authoring a
-- third, fully-attributed MORBIDITY_REPORT row (MORB_RPT_KEY=22015000) in
-- RDB_MODERN with full demographics (D_PATIENT row 22015100), provider /
-- reporter (D_PROVIDER rows 22015110/22015111), reporting-facility /
-- hospital orgs (D_ORGANIZATION rows 22015120/22015121), three LAB_TEST
-- 'Result' rows + LAB_TEST_RESULT + LAB_RESULT_VAL + LAB_RESULT_COMMENT
-- (LAB_TEST_KEYs 22015300-22015302), and three TREATMENT + TREATMENT_EVENT
-- rows (TREATMENT_KEYs 22015400-22015402). EVENT_METRIC row for
-- 22015000 carries MORB_REPORT_CREATE_DATE / MORB_REPORT_LAST_UPDATED_DATE.
--
-- BASELINE (live, 2026-05-24, after fresh SP rerun): 86/133 populated.
--
-- STRATEGY
--   The morbidity datamart SP (dbo.sp_morbidity_report_datamart_postprocessing)
--   reads exclusively from RDB_MODERN dimension + event tables:
--     - MORBIDITY_REPORT + MORBIDITY_REPORT_EVENT (main fact)
--     - D_PATIENT, D_PROVIDER (physician + reporter), D_ORGANIZATION
--       (rep_fac + hsptl), INVESTIGATION, EVENT_METRIC, CONDITION, RDB_DATE
--     - LAB_TEST + LAB_TEST_RESULT + LAB_RESULT_VAL + LAB_RESULT_COMMENT
--       (joined on LAB_RPT_LOCAL_ID + filter LAB_TEST_TYPE='Result' for the
--       _1/_2/_3 lab pivot)
--     - TREATMENT_EVENT + TREATMENT + RDB_DATE (treatment pivot)
--
--   The SP filters morbidity reports via OR-chain over @obs_uids /
--   @pat_uids / @prov_uids / @org_uids / @inv_uids. The orchestrator
--   passes PAT_UIDS='20000000,20020010,20020020', PRV_UIDS includes
--   20010010 (Tier1 v2 Provider), ORG_UIDS includes 20030010 (Tier1 v2
--   Org), and PHC_UIDS includes 20000100 + 20050010 + 22015XXX. None of
--   my new dim UIDs (22015100/110/111/120/121/200) are in those lists, so
--   to keep this fixture self-driven without an ORCH_TODO, I pin the new
--   morb to existing UIDs:
--     - MORBIDITY_REPORT.MORB_RPT_UID = 22015000 — added to MORB_OBS_UIDS
--       via ORCH_TODO (cleanest), OR alternatively pickable via dim FKs.
--     - D_PATIENT.PATIENT_UID = 20020010 (Variant Marie) → matches the
--       orchestrator's PAT_UIDS, so the SP's pat-filter picks our new
--       MORB_RPT row up automatically even without orchestrator changes.
--
--   Lab and treatment _2/_3 columns are produced by ROW_NUMBER() pivots
--   over LAB_TEST_RESULT / TREATMENT_EVENT rows joined to the morb. We
--   author exactly 3 of each so all _1, _2, _3 suffixes land.
--
-- TARGETED COLUMN GAINS (relative to 86/133 baseline)
--   24 lab cols : SPECIMEN_COLLECTION_DATE_{1..3}, LAB_REPORT_DATE_{1..3},
--                 RESULTED_TEST_NAME_{1..3}, RESULTED_TEST_RESULT_{1..3},
--                 RESULTED_TEST_TEXT_RESULT_{1..3},
--                 RESULTED_TEST_NUMERIC_CONCAT_{1..3},
--                 LAB_RESULT_COMMENTS_{1..3}, SPECIMEN_SOURCE_{1..3}
--   10 treatment cols : TREATMENT_DATE_{2,3}, TREATMENT_NAME_{2,3},
--                       TREATMENT_COMMENTS_{2,3},
--                       TREATMENT_CUSTOM_NAME_{1..3}
--    7 patient demographic cols : PATIENT_MIDDLE_NAME, PATIENT_NAME_SUFFIX,
--                                 PATIENT_GENERAL_COMMENTS, PATIENT_SSN,
--                                 PATIENT_DECEASED_DATE,
--                                 PATIENT_PHONE_EXT_HOME, PATIENT_PHONE_EXT_WORK
--    5 dim _2/ext cols : PROVIDER_STREET_ADDR_2, REPORT_FAC_STREET_ADDR_2,
--                        REPORT_FAC_PHONE_EXT, REPORTER_STREET_ADDR_2,
--                        HOSPITAL_FAC_STREET_ADDR_2, HOSPITAL_FAC_PHONE_EXT
--    1 morb date col : MORBIDITY_REPORT_DATE  (MORB_RPT_DT_KEY=5935 → 2026-04-01)
--   ---------------------------------------------------------------------
--   Target gain : ~47 cols → 86 + 47 = 133/133 (theoretical max).
--   Realistic target: 130/133 (a few _2/ext fields may NULLIF to NULL or
--   get blocked by SP edge cases).
--
-- UID BLOCK (this fixture): 22015000-22015999
--   22015000  MORB_RPT_KEY + MORB_RPT_UID for the new morbidity report
--   22015100  PATIENT_KEY (D_PATIENT) — full demographics; PATIENT_UID
--             reuses 20020010 (Variant Marie) so orch's @pat_uids picks
--             the morb up without an ORCH_TODO change
--   22015110  PROVIDER_KEY for physician (street_addr_2, phone_ext_work)
--   22015111  PROVIDER_KEY for reporter (street_addr_2)
--   22015120  ORGANIZATION_KEY for reporting facility (street_addr_2,
--             phone_ext_work)
--   22015121  ORGANIZATION_KEY for hospital (street_addr_2,
--             phone_ext_work)
--   22015200  INVESTIGATION_KEY (links morb_event → INVESTIGATION → case)
--   22015300-22015302  LAB_TEST_KEYs (3 Result-type lab rows)
--   22015400-22015402  TREATMENT_KEYs (3 treatment rows)
--   22015500-22015502  TEST_RESULT_GRP_KEYs (1 per Result row)
--   22015600-22015602  RESULT_COMMENT_GRP_KEYs (1 per Result row)
--   22015700-22015702  LAB_RESULT_COMMENT_KEYs
--   22015800-22015802  LAB_TEST_UIDs (used as FKs in LRV / LRC for grouping)
--
-- IDEMPOTENCY
--   Each block guarded by IF NOT EXISTS on its first allocated UID.
--   Safe to re-run; second invocation is a no-op (except tail SP exec).
--
-- TAIL-EXEC
--   sp_morbidity_report_datamart_postprocessing is invoked at the bottom
--   with the orchestrator's stock @obs_uids + @pat_uids + @prov_uids +
--   @org_uids + @inv_uids list extended with my new morb UID
--   (22015000), patient UID (20020010 already in PAT_UIDS), and the new
--   investigation UID 22015200. Wrapped in TRY/CATCH.
--
-- ORCH_TODO (optional, for cleanliness)
--   Add 22015000 to MORB_OBS_UIDS in scripts/merge_and_verify.sh:452 so
--   the orchestrator's Step-9 SP rerun continues to pick up this morb
--   even if PAT_UIDS were ever to drop 20020010. Today this is redundant
--   because PAT_UIDS already includes 20020010 (Variant Marie), and the
--   SP's OR-chain over filters does the matching.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------- Sentinels / locals ----------
DECLARE @user        bigint   = 10009282;          -- conventional superuser id
DECLARE @t           datetime = '2026-04-01T00:00:00';
DECLARE @add_user_nm varchar(100) = 'Diamond, Adam';
DECLARE @last_chg_nm varchar(100) = 'Diamond, Adam';

-- ---------- Existing reused UIDs ----------
DECLARE @existing_patient_uid bigint = 20020010;  -- Variant Marie Patient (in PAT_UIDS)
DECLARE @existing_condition_key bigint = 15;      -- Hepatitis A, acute
DECLARE @existing_rdb_date_key bigint = 5935;     -- 2026-04-01 (already in dbo.RDB_DATE)
DECLARE @existing_rdb_date_key_apr04 bigint = 5938; -- 2026-04-04
DECLARE @existing_rdb_date_key_apr02 bigint = 5936; -- 2026-04-02

-- ---------- New UIDs (this fixture) ----------
DECLARE @new_morb_key bigint = 22015000;
DECLARE @new_morb_uid bigint = 22015000;

DECLARE @new_patient_key bigint = 22015100;

DECLARE @new_physician_key bigint = 22015110;
DECLARE @new_physician_uid bigint = 22015110;
DECLARE @new_reporter_key bigint = 22015111;
DECLARE @new_reporter_uid bigint = 22015111;

DECLARE @new_repfac_org_key bigint = 22015120;
DECLARE @new_repfac_org_uid bigint = 22015120;
DECLARE @new_hsptl_org_key bigint = 22015121;
DECLARE @new_hsptl_org_uid bigint = 22015121;

DECLARE @new_inv_key bigint = 22015200;
DECLARE @new_inv_uid bigint = 22015200;

DECLARE @new_lab_test_key_1 bigint = 22015300;
DECLARE @new_lab_test_key_2 bigint = 22015301;
DECLARE @new_lab_test_key_3 bigint = 22015302;
DECLARE @new_lab_test_uid_1 bigint = 22015800;
DECLARE @new_lab_test_uid_2 bigint = 22015801;
DECLARE @new_lab_test_uid_3 bigint = 22015802;

DECLARE @new_test_result_grp_key_1 bigint = 22015500;
DECLARE @new_test_result_grp_key_2 bigint = 22015501;
DECLARE @new_test_result_grp_key_3 bigint = 22015502;

DECLARE @new_result_comment_grp_key_1 bigint = 22015600;
DECLARE @new_result_comment_grp_key_2 bigint = 22015601;
DECLARE @new_result_comment_grp_key_3 bigint = 22015602;

DECLARE @new_lab_result_comment_key_1 bigint = 22015700;
DECLARE @new_lab_result_comment_key_2 bigint = 22015701;
DECLARE @new_lab_result_comment_key_3 bigint = 22015702;

DECLARE @new_treatment_key_1 bigint = 22015400;
DECLARE @new_treatment_key_2 bigint = 22015401;
DECLARE @new_treatment_key_3 bigint = 22015402;

-- =====================================================================
-- D_PATIENT — full demographics including DECEASED_DATE.
-- PATIENT_UID reused (Variant Marie 20020010) so orch's @pat_uids filter
-- picks the new morb up. PATIENT_KEY=22015100 is unique.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_PATIENT WHERE PATIENT_KEY = 22015100)
BEGIN
    INSERT INTO dbo.D_PATIENT (
        PATIENT_KEY, PATIENT_UID, PATIENT_RECORD_STATUS,
        PATIENT_LOCAL_ID, PATIENT_GENERAL_COMMENTS,
        PATIENT_FIRST_NAME, PATIENT_MIDDLE_NAME, PATIENT_LAST_NAME,
        PATIENT_NAME_SUFFIX, PATIENT_STREET_ADDRESS_1, PATIENT_STREET_ADDRESS_2,
        PATIENT_CITY, PATIENT_STATE, PATIENT_ZIP, PATIENT_COUNTY,
        PATIENT_COUNTRY,
        PATIENT_PHONE_HOME, PATIENT_PHONE_EXT_HOME,
        PATIENT_PHONE_WORK, PATIENT_PHONE_EXT_WORK,
        PATIENT_DOB, PATIENT_AGE_REPORTED, PATIENT_AGE_REPORTED_UNIT,
        PATIENT_CURRENT_SEX, PATIENT_DECEASED_INDICATOR, PATIENT_DECEASED_DATE,
        PATIENT_MARITAL_STATUS, PATIENT_SSN, PATIENT_ETHNICITY,
        PATIENT_RACE_CALCULATED, PATIENT_RACE_CALC_DETAILS
    ) VALUES (
        @new_patient_key, @existing_patient_uid, N'ACTIVE',
        N'PSN20020010GA01', N'Morb enrich — full-demographic patient for SP coverage.',
        N'Morbid', N'Demographic', N'Coverage',
        N'Jr.', N'500 Coverage Drive Unit A', N'Apartment B-12',
        N'Atlanta', N'Georgia', N'30303', N'Fulton County',
        N'United States',
        N'404-555-9000', N'7777',
        N'404-555-9001', N'8888',
        '1990-06-15', 36, N'YEARS',
        N'F', N'Y', '2026-04-15T00:00:00',
        N'Married', N'111-22-3333', N'Not Hispanic or Latino',
        N'White', N'White (1 race reported)'
    );
END
GO

-- =====================================================================
-- D_PROVIDER — physician + reporter, each with street_addr_2 + phone_ext.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER WHERE PROVIDER_KEY = 22015110)
BEGIN
    INSERT INTO dbo.D_PROVIDER (
        PROVIDER_KEY, PROVIDER_UID, PROVIDER_RECORD_STATUS,
        PROVIDER_LOCAL_ID, PROVIDER_FIRST_NAME, PROVIDER_LAST_NAME,
        PROVIDER_STREET_ADDRESS_1, PROVIDER_STREET_ADDRESS_2,
        PROVIDER_CITY, PROVIDER_STATE, PROVIDER_ZIP,
        PROVIDER_COUNTRY,
        PROVIDER_PHONE_WORK, PROVIDER_PHONE_EXT_WORK,
        PROVIDER_ENTRY_METHOD, PROVIDER_ADD_TIME, PROVIDER_LAST_CHANGE_TIME,
        PROVIDER_ADDED_BY, PROVIDER_LAST_UPDATED_BY
    ) VALUES (
        22015110, 22015110, N'ACTIVE',
        N'PSN22015110GA01', N'Phys', N'Coverage',
        N'600 Physician Plaza Suite 3A', N'Building West Wing',
        N'Atlanta', N'Georgia', N'30303',
        N'United States',
        N'404-555-9110', N'1111',
        N'ELECTRONIC', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
        N'Diamond, Adam', N'Diamond, Adam'
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER WHERE PROVIDER_KEY = 22015111)
BEGIN
    INSERT INTO dbo.D_PROVIDER (
        PROVIDER_KEY, PROVIDER_UID, PROVIDER_RECORD_STATUS,
        PROVIDER_LOCAL_ID, PROVIDER_FIRST_NAME, PROVIDER_LAST_NAME,
        PROVIDER_STREET_ADDRESS_1, PROVIDER_STREET_ADDRESS_2,
        PROVIDER_CITY, PROVIDER_STATE, PROVIDER_ZIP,
        PROVIDER_COUNTRY,
        PROVIDER_PHONE_WORK, PROVIDER_PHONE_EXT_WORK,
        PROVIDER_ENTRY_METHOD, PROVIDER_ADD_TIME, PROVIDER_LAST_CHANGE_TIME,
        PROVIDER_ADDED_BY, PROVIDER_LAST_UPDATED_BY
    ) VALUES (
        22015111, 22015111, N'ACTIVE',
        N'PSN22015111GA01', N'Repr', N'Coverage',
        N'700 Reporter Way', N'Floor 5',
        N'Atlanta', N'Georgia', N'30303',
        N'United States',
        N'404-555-9111', N'2222',
        N'ELECTRONIC', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
        N'Diamond, Adam', N'Diamond, Adam'
    );
END
GO

-- =====================================================================
-- D_ORGANIZATION — reporting facility + hospital, each with street_2 + ext.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_KEY = 22015120)
BEGIN
    INSERT INTO dbo.D_ORGANIZATION (
        ORGANIZATION_KEY, ORGANIZATION_UID, ORGANIZATION_RECORD_STATUS,
        ORGANIZATION_LOCAL_ID, ORGANIZATION_NAME,
        ORGANIZATION_STREET_ADDRESS_1, ORGANIZATION_STREET_ADDRESS_2,
        ORGANIZATION_CITY, ORGANIZATION_STATE, ORGANIZATION_ZIP,
        ORGANIZATION_COUNTRY,
        ORGANIZATION_PHONE_WORK, ORGANIZATION_PHONE_EXT_WORK,
        ORGANIZATION_ENTRY_METHOD, ORGANIZATION_ADD_TIME, ORGANIZATION_LAST_CHANGE_TIME,
        ORGANIZATION_ADDED_BY, ORGANIZATION_LAST_UPDATED_BY
    ) VALUES (
        22015120, 22015120, N'ACTIVE',
        N'ORG22015120GA01', N'Coverage Reporting Facility',
        N'800 Reporting Facility Blvd', N'Suite 200',
        N'Atlanta', N'Georgia', N'30303',
        N'United States',
        N'404-555-9120', N'3333',
        N'ELECTRONIC', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
        N'Diamond, Adam', N'Diamond, Adam'
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_KEY = 22015121)
BEGIN
    INSERT INTO dbo.D_ORGANIZATION (
        ORGANIZATION_KEY, ORGANIZATION_UID, ORGANIZATION_RECORD_STATUS,
        ORGANIZATION_LOCAL_ID, ORGANIZATION_NAME,
        ORGANIZATION_STREET_ADDRESS_1, ORGANIZATION_STREET_ADDRESS_2,
        ORGANIZATION_CITY, ORGANIZATION_STATE, ORGANIZATION_ZIP,
        ORGANIZATION_COUNTRY,
        ORGANIZATION_PHONE_WORK, ORGANIZATION_PHONE_EXT_WORK,
        ORGANIZATION_ENTRY_METHOD, ORGANIZATION_ADD_TIME, ORGANIZATION_LAST_CHANGE_TIME,
        ORGANIZATION_ADDED_BY, ORGANIZATION_LAST_UPDATED_BY
    ) VALUES (
        22015121, 22015121, N'ACTIVE',
        N'ORG22015121GA01', N'Coverage Hospital',
        N'900 Hospital Drive Suite 100', N'East Tower 4F',
        N'Atlanta', N'Georgia', N'30303',
        N'United States',
        N'404-555-9121', N'4444',
        N'ELECTRONIC', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
        N'Diamond, Adam', N'Diamond, Adam'
    );
END
GO

-- =====================================================================
-- INVESTIGATION — new entry so morb→inv links resolve to a populated row
-- (the SP NULLIFs INVESTIGATION_KEY=1 to NULL, but a real key surfaces
-- INVESTIGATION_CREATED_IND='Yes' + CASE_STATUS).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.INVESTIGATION WHERE INVESTIGATION_KEY = 22015200)
BEGIN
    INSERT INTO dbo.INVESTIGATION (INVESTIGATION_KEY, CASE_UID, INV_CASE_STATUS, RECORD_STATUS_CD)
    VALUES (22015200, 22015200, N'Probable', N'ACTIVE');
END
GO

-- =====================================================================
-- MORBIDITY_REPORT — the actual fact row.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.MORBIDITY_REPORT WHERE MORB_RPT_KEY = 22015000)
BEGIN
    -- Note: MORB_RPT_OID is numeric(9). Use the morb UID as the OID value.
    -- JURISDICTION_CD is varchar(20); we use a string code consistent with
    -- existing rows (e.g. '130001' = Fulton County) but 'GA' would also work.
    INSERT INTO dbo.MORBIDITY_REPORT (
        MORB_RPT_KEY, MORB_RPT_UID, MORB_RPT_LOCAL_ID,
        MORB_RPT_SHARE_IND, MORB_RPT_OID,
        MORB_RPT_TYPE, MORB_RPT_COMMENTS, MORB_RPT_DELIVERY_METHOD,
        SUSPECT_FOOD_WTRBORNE_ILLNESS, MORB_RPT_OTHER_SPECIFY,
        NURSING_HOME_ASSOCIATE_IND, JURISDICTION_CD, JURISDICTION_NM,
        HEALTHCARE_ORG_ASSOCIATE_IND,
        MORB_RPT_LAST_UPDATE_DT,
        DIAGNOSIS_DT, HSPTL_ADMISSION_DT, PH_RECEIVE_DT,
        DIE_FROM_ILLNESS_IND, HOSPITALIZED_IND, PREGNANT_IND,
        FOOD_HANDLER_IND, DAYCARE_IND, ELECTRONIC_IND,
        RECORD_STATUS_CD, RDB_LAST_REFRESH_TIME,
        PROCESSING_DECISION_CD, PROCESSING_DECISION_DESC
    ) VALUES (
        22015000, 22015000, N'OBS22015000GA01',
        N'T', 22015000,
        N'INIT', N'Morb enrich — fully attributed morbidity report for SP coverage.', N'Web',
        N'Y', N'Suspect foodborne; ill at restaurant.',
        N'N', N'130001', N'Fulton County',
        N'N',
        '2026-04-05T10:30:00',
        '2026-04-02T00:00:00', '2026-04-02T08:30:00', '2026-04-04T09:00:00',
        N'N', N'Y', N'N',
        N'N', N'N', N'E',
        N'ACTIVE', '2026-04-05T10:30:00',
        N'PROCESS', N'Processed'
    );
END
GO

-- =====================================================================
-- MORBIDITY_REPORT_EVENT — the link row to dimensions.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.MORBIDITY_REPORT_EVENT WHERE MORB_RPT_KEY = 22015000)
BEGIN
    INSERT INTO dbo.MORBIDITY_REPORT_EVENT (
        NURSING_HOME_KEY, HEALTH_CARE_KEY, MORB_RPT_CREATE_DT_KEY,
        HSPTL_DISCHARGE_DT_KEY, ILLNESS_ONSET_DT_KEY, MORB_RPT_SRC_ORG_KEY,
        PATIENT_KEY, MORB_RPT_KEY, MORB_RPT_DT_KEY,
        PHYSICIAN_KEY, REPORTER_KEY, HSPTL_KEY,
        MORB_RPT_COUNT, INVESTIGATION_KEY, CONDITION_KEY,
        LDF_GROUP_KEY, RECORD_STATUS_CD
    ) VALUES (
        1, 1, 5935,                       -- nursing_home, health_care, create_dt(2026-04-01)
        5938, 5935, 22015120,             -- discharge_dt(2026-04-04), illness_onset(2026-04-01), rep_fac_org=22015120
        22015100, 22015000, 5935,         -- patient=22015100, morb=22015000, morb_rpt_dt=2026-04-01
        22015110, 22015111, 22015121,     -- physician=22015110, reporter=22015111, hsptl=22015121
        1, 22015200, 15,                  -- inv=22015200, condition_key=15 (Hep A)
        1, N'ACTIVE'
    );
END
GO

-- =====================================================================
-- EVENT_METRIC — drives MORB_REPORT_CREATE_DATE / LAST_UPDATED_DATE /
-- MORB_REPORT_CREATED_BY / MORB_REPORT_LAST_UPDATED_BY in the datamart.
-- Joined by EVENT_METRIC.EVENT_UID = MR.MORB_RPT_UID.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.EVENT_METRIC WHERE EVENT_UID = 22015000)
BEGIN
    INSERT INTO dbo.EVENT_METRIC (
        EVENT_TYPE, EVENT_UID, LOCAL_ID, PROG_AREA_CD, PROG_AREA_DESC_TXT,
        JURISDICTION_CD, JURISDICTION_DESC_TXT, RECORD_STATUS_CD,
        ELECTRONIC_IND, STATUS_CD,
        ADD_TIME, ADD_USER_ID, ADD_USER_NAME,
        LAST_CHG_TIME, LAST_CHG_USER_ID, LAST_CHG_USER_NAME
    ) VALUES (
        N'MOR', 22015000, N'OBS22015000GA01', N'STD', N'Sexually Transmitted Disease',
        N'GA', N'Georgia', N'ACTIVE',
        N'E', N'ACTIVE',
        '2026-04-04T09:00:00', 10009282, N'Coverage, Author',
        '2026-04-05T10:30:00', 10009282, N'Diamond, Adam'
    );
END
GO

-- =====================================================================
-- LAB_TEST — 3 Result-type rows for the lab pivot.
-- LAB_TEST_KEY is the join target for LTR; LAB_TEST_TYPE='Result' is the
-- filter for the lab-pivot CTE; LAB_RPT_LOCAL_ID is the equi-join key
-- between #MORB_TO_LAB_KEYS and #MORB_LAB_RESULTS.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_TEST WHERE LAB_TEST_KEY = 22015300)
BEGIN
    INSERT INTO dbo.LAB_TEST (
        LAB_TEST_KEY, LAB_TEST_UID, LAB_RPT_LOCAL_ID,
        LAB_TEST_CD, LAB_TEST_CD_DESC, LAB_TEST_TYPE,
        LAB_TEST_DT, SPECIMEN_COLLECTION_DT,
        CLINICAL_INFORMATION, RECORD_STATUS_CD,
        JURISDICTION_CD, JURISDICTION_NM, LAB_TEST_CD_SYS_CD, LAB_TEST_CD_SYS_NM,
        LAB_RPT_RECEIVED_BY_PH_DT, LAB_TEST_STATUS,
        RDB_LAST_REFRESH_TIME
    ) VALUES
    (22015300, 22015800, N'OBS22015300GA01',
     N'80375-5', N'Hepatitis A virus IgM Ab', N'Result',
     '2026-04-04T08:00:00', '2026-04-03T18:00:00',
     N'Serum', N'ACTIVE',
     N'GA', N'Georgia', N'2.16.840.1.113883.6.1', N'LOINC',
     '2026-04-04T09:00:00', N'Final',
     '2026-04-05T10:30:00'),
    (22015301, 22015801, N'OBS22015301GA01',
     N'22314-9', N'Hepatitis A virus IgG Ab', N'Result',
     '2026-04-05T09:00:00', '2026-04-04T18:00:00',
     N'Plasma', N'ACTIVE',
     N'GA', N'Georgia', N'2.16.840.1.113883.6.1', N'LOINC',
     '2026-04-05T11:00:00', N'Final',
     '2026-04-05T11:30:00'),
    (22015302, 22015802, N'OBS22015302GA01',
     N'1742-6', N'Alanine aminotransferase (ALT)', N'Result',
     '2026-04-06T09:00:00', '2026-04-05T18:00:00',
     N'Serum', N'ACTIVE',
     N'GA', N'Georgia', N'2.16.840.1.113883.6.1', N'LOINC',
     '2026-04-06T11:00:00', N'Final',
     '2026-04-06T11:30:00');
END
GO

-- =====================================================================
-- TEST_RESULT_GROUPING / RESULT_COMMENT_GROUP — parent grouping rows
-- required by FK from LAB_RESULT_VAL / LAB_RESULT_COMMENT respectively.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.TEST_RESULT_GROUPING WHERE TEST_RESULT_GRP_KEY = 22015500)
BEGIN
    INSERT INTO dbo.TEST_RESULT_GROUPING (TEST_RESULT_GRP_KEY, LAB_TEST_UID, RDB_LAST_REFRESH_TIME) VALUES
        (22015500, 22015800, '2026-04-05T10:30:00'),
        (22015501, 22015801, '2026-04-05T11:30:00'),
        (22015502, 22015802, '2026-04-06T11:30:00');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.RESULT_COMMENT_GROUP WHERE RESULT_COMMENT_GRP_KEY = 22015600)
BEGIN
    INSERT INTO dbo.RESULT_COMMENT_GROUP (RESULT_COMMENT_GRP_KEY, LAB_TEST_UID, RDB_LAST_REFRESH_TIME) VALUES
        (22015600, 22015800, '2026-04-05T10:30:00'),
        (22015601, 22015801, '2026-04-05T11:30:00'),
        (22015602, 22015802, '2026-04-06T11:30:00');
END
GO

-- =====================================================================
-- LAB_RESULT_VAL — one row per Result lab. TEST_RESULT_GRP_KEY is the
-- LTR.TEST_RESULT_GRP_KEY FK target. Provides RESULTED_TEST_RESULT_x
-- (TEST_RESULT_VAL_CD_DESC), RESULTED_TEST_NUMERIC_CONCAT_x
-- (NUMERIC_RESULT + RESULT_UNITS concat), RESULTED_TEST_TEXT_RESULT_x
-- (LAB_RESULT_TXT_VAL).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_RESULT_VAL WHERE TEST_RESULT_GRP_KEY = 22015500)
BEGIN
    INSERT INTO dbo.LAB_RESULT_VAL (
        TEST_RESULT_GRP_KEY, NUMERIC_RESULT, RESULT_UNITS,
        LAB_RESULT_TXT_VAL, TEST_RESULT_VAL_CD, TEST_RESULT_VAL_CD_DESC,
        TEST_RESULT_VAL_CD_SYS_CD, TEST_RESULT_VAL_CD_SYS_NM,
        TEST_RESULT_VAL_KEY, RECORD_STATUS_CD, LAB_TEST_UID,
        RDB_LAST_REFRESH_TIME
    ) VALUES
    (22015500, 1.5, N'Index', N'Reactive — IgM antibody to HAV detected.',
     N'10828004', N'Positive',
     N'2.16.840.1.113883.6.96', N'SNOMED-CT',
     22015500, N'ACTIVE', 22015800, '2026-04-05T10:30:00'),
    (22015501, 0.8, N'Index', N'Non-reactive — IgG antibody to HAV not detected.',
     N'260385009', N'Negative',
     N'2.16.840.1.113883.6.96', N'SNOMED-CT',
     22015501, N'ACTIVE', 22015801, '2026-04-05T11:30:00'),
    (22015502, 215, N'U/L', N'Elevated; ULN ~40 U/L.',
     N'75540009', N'High',
     N'2.16.840.1.113883.6.96', N'SNOMED-CT',
     22015502, N'ACTIVE', 22015802, '2026-04-06T11:30:00');
END
GO

-- =====================================================================
-- LAB_RESULT_COMMENT — one row per Result lab. RESULT_COMMENT_GRP_KEY is
-- the LTR.RESULT_COMMENT_GRP_KEY FK target. Provides LAB_RESULT_COMMENTS_x.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_RESULT_COMMENT WHERE LAB_RESULT_COMMENT_KEY = 22015700)
BEGIN
    INSERT INTO dbo.LAB_RESULT_COMMENT (
        LAB_TEST_UID, LAB_RESULT_COMMENT_KEY, LAB_RESULT_COMMENTS,
        RESULT_COMMENT_GRP_KEY, RECORD_STATUS_CD, RDB_LAST_REFRESH_TIME
    ) VALUES
    (22015800, 22015700, N'IgM positive — acute Hep A.', 22015600, N'ACTIVE', '2026-04-05T10:30:00'),
    (22015801, 22015701, N'IgG negative — no prior immunity.', 22015601, N'ACTIVE', '2026-04-05T11:30:00'),
    (22015802, 22015702, N'ALT elevated — consistent with hepatitis.', 22015602, N'ACTIVE', '2026-04-06T11:30:00');
END
GO

-- =====================================================================
-- LAB_TEST_RESULT — links labs to MORB_RPT_KEY=22015000 with grouping
-- keys that resolve to the LRV / LRC rows above.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_TEST_RESULT WHERE LAB_TEST_KEY = 22015300 AND MORB_RPT_KEY = 22015000)
BEGIN
    INSERT INTO dbo.LAB_TEST_RESULT (
        LAB_TEST_KEY, LAB_TEST_UID, RESULT_COMMENT_GRP_KEY, TEST_RESULT_GRP_KEY,
        PERFORMING_LAB_KEY, PATIENT_KEY, COPY_TO_PROVIDER_KEY,
        LAB_TEST_TECHNICIAN_KEY, SPECIMEN_COLLECTOR_KEY,
        ORDERING_ORG_KEY, REPORTING_LAB_KEY, CONDITION_KEY,
        LAB_RPT_DT_KEY, MORB_RPT_KEY, INVESTIGATION_KEY,
        LDF_GROUP_KEY, ORDERING_PROVIDER_KEY, RECORD_STATUS_CD,
        RDB_LAST_REFRESH_TIME
    ) VALUES
    (22015300, 22015800, 22015600, 22015500,
     22015120, 22015100, 22015110, 22015110, 22015110,
     22015120, 22015120, 15,
     5938, 22015000, 22015200,
     1, 22015110, N'ACTIVE',
     '2026-04-05T10:30:00'),
    (22015301, 22015801, 22015601, 22015501,
     22015120, 22015100, 22015110, 22015110, 22015110,
     22015120, 22015120, 15,
     5938, 22015000, 22015200,
     1, 22015110, N'ACTIVE',
     '2026-04-05T11:30:00'),
    (22015302, 22015802, 22015602, 22015502,
     22015120, 22015100, 22015110, 22015110, 22015110,
     22015120, 22015120, 15,
     5938, 22015000, 22015200,
     1, 22015110, N'ACTIVE',
     '2026-04-06T11:30:00');
END
GO

-- =====================================================================
-- TREATMENT — 3 rows feeding TREATMENT_NAME_{1..3}, TREATMENT_COMMENTS_{1..3},
-- TREATMENT_CUSTOM_NAME_{1..3}. Joined to morb via TREATMENT_EVENT.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.TREATMENT WHERE TREATMENT_KEY = 22015400)
BEGIN
    -- Note: TREATMENT_OID is bigint (despite the OID suffix); TREATMENT_DOSAGE_*
    -- columns are varchar. Use the treatment_key as the OID value.
    INSERT INTO dbo.TREATMENT (
        TREATMENT_KEY, TREATMENT_UID, TREATMENT_LOCAL_ID,
        TREATMENT_NM, TREATMENT_DRUG, TREATMENT_DOSAGE_STRENGTH,
        TREATMENT_DOSAGE_STRENGTH_UNIT, TREATMENT_FREQUENCY,
        TREATMENT_DURATION, TREATMENT_DURATION_UNIT,
        TREATMENT_COMMENTS, TREATMENT_ROUTE,
        CUSTOM_TREATMENT, TREATMENT_SHARED_IND, TREATMENT_OID, RECORD_STATUS_CD
    ) VALUES
    (22015400, 22015400, N'TRT22015400GA01',
     N'Hepatitis A IG, 0.1 mL/kg, IM, x 1', N'HepA IG', N'0.1',
     N'mL/kg', N'Once',
     N'1', N'dose',
     N'Post-exposure prophylaxis; administered within 14 days.', N'IM',
     N'HepA Immune Globulin (custom name)', N'T', 22015400, N'ACTIVE'),
    (22015401, 22015401, N'TRT22015401GA01',
     N'Acetaminophen, 500 mg, PO, q6h, x 5d', N'Acetaminophen', N'500',
     N'mg', N'Every 6 hours',
     N'5', N'days',
     N'Antipyretic; max 3 g/day.', N'PO',
     N'Acetaminophen 500mg (custom name)', N'T', 22015401, N'ACTIVE'),
    (22015402, 22015402, N'TRT22015402GA01',
     N'IV Fluids, normal saline, 1L, x 1', N'Normal Saline 0.9%', N'1000',
     N'mL', N'Once',
     N'1', N'dose',
     N'Supportive hydration during acute illness.', N'IV',
     N'IV Saline Bolus (custom name)', N'T', 22015402, N'ACTIVE');
END
GO

-- =====================================================================
-- TREATMENT_EVENT — links each treatment to MORB_RPT_KEY=22015000.
-- TREATMENT_DT_KEY → RDB_DATE → DATE_MM_DD_YYYY → TREATMENT_DATE_{1..3}.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.TREATMENT_EVENT WHERE TREATMENT_KEY = 22015400 AND MORB_RPT_KEY = 22015000)
BEGIN
    INSERT INTO dbo.TREATMENT_EVENT (
        TREATMENT_DT_KEY, TREATMENT_PROVIDING_ORG_KEY, PATIENT_KEY,
        TREATMENT_COUNT, TREATMENT_KEY, MORB_RPT_KEY,
        TREATMENT_PHYSICIAN_KEY, INVESTIGATION_KEY, CONDITION_KEY,
        LDF_GROUP_KEY, RECORD_STATUS_CD
    ) VALUES
    (5935, 22015120, 22015100, 1, 22015400, 22015000,
     22015110, 22015200, 15, 1, N'ACTIVE'),
    (5936, 22015120, 22015100, 1, 22015401, 22015000,
     22015110, 22015200, 15, 1, N'ACTIVE'),
    (5938, 22015120, 22015100, 1, 22015402, 22015000,
     22015110, 22015200, 15, 1, N'ACTIVE');
END
GO

-- =====================================================================
-- TAIL EXEC — re-run sp_morbidity_report_datamart_postprocessing.
-- @obs_uids   adds 22015000.
-- @pat_uids   stock orch list + new patient_uid (20020010 already present).
-- @inv_uids   stock orch list (uses PHC_UIDS in orchestrator) + 22015200.
-- @prov_uids  + 22015110, 22015111.
-- @org_uids   + 22015120, 22015121.
-- =====================================================================
BEGIN TRY
    EXEC dbo.sp_morbidity_report_datamart_postprocessing
        @obs_uids = N'20000130,20080010,22015000',
        @pat_uids = N'20000000,20020010,20020020',
        @prov_uids = N'20000010,20010010,22015110,22015111',
        @org_uids = N'20000020,20030010,22015120,22015121',
        @inv_uids = N'20000100,20050010,22015200',
        @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'TAIL EXEC FAILED:';
    PRINT ERROR_MESSAGE();
    PRINT '  line=' + CAST(ERROR_LINE() AS varchar(10)) +
          ' nbr=' + CAST(ERROR_NUMBER() AS varchar(10)) +
          ' state=' + CAST(ERROR_STATE() AS varchar(10));
END CATCH
GO
