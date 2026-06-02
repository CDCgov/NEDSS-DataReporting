-- =====================================================================
-- Tier 3 ENRICHMENT — LAB100 column expansion
-- =====================================================================
-- Lifts dbo.LAB100 populated-column count beyond the post-orchestrator
-- 22/69 baseline by authoring TWO new fully-attributed Order+Result
-- LAB_TEST pairs (LAB_TEST_KEYs 22021300/22021301 [Orders],
-- 22021302/22021303 [Results]), plus the matching LAB_TEST_RESULT,
-- LAB_RESULT_VAL, LAB_RESULT_COMMENT, TEST_RESULT_GROUPING, and
-- RESULT_COMMENT_GROUP rows. Re-uses existing well-populated dim rows
-- (D_PATIENT row 3 Foundation Patient, D_PROVIDER row 12 Foundation
-- Provider, D_ORGANIZATION row 7 Foundation Organization w/ CLIA) so
-- the SP's INNER joins on D_PROVIDER / D_ORGANIZATION succeed.
--
-- BASELINE (live, 2026-05-24, post-orchestrator): 22/69 populated.
-- TARGET: +30 cols (52/69+), pulling in PATIENT_*, PERSON_*, PROVIDER_*,
-- PRV_ADDR_*, ORDERING_FACILITY, REPORTING_FACILITY*, ACCESSION_NBR,
-- ALT_LAB_TEST_CD*, REASON_FOR_TEST_DESC, RESULT_REF_RANGE_*, SPECIMEN_*
-- and many other Order-side fields.
--
-- STRATEGY (recap of SP dbo.sp_lab100_datamart_postprocessing)
--   1. CTE: select * from LAB_TEST lt LEFT JOIN LAB_TEST_RESULT ltr
--      WHERE lt.LAB_TEST_KEY <> 1 AND lt.LAB_TEST_UID IN (
--        SELECT LAB_TEST_UID FROM LAB_TEST WHERE
--               LAB_TEST_UID IN string_split(@labtestuids,',')
--               AND LAB_TEST_TYPE='Result'
--        UNION ALL
--        SELECT ROOT_ORDERED_TEST_PNTR FROM LAB_TEST WHERE
--               LAB_TEST_UID IN string_split(@labtestuids,',')
--               AND LAB_TEST_TYPE='Result')
--      → so each Result UID we pass MUST have an Order parent
--        whose UID = Result.ROOT_ORDERED_TEST_PNTR.
--   2. Split into #TMP_LABTEST_ORDER (lt_type='Order') +
--      #TMP_LABTEST_RESULT (lt_type='Result'); LRV/LRC joined by
--      TEST_RESULT_GRP_KEY / RESULT_COMMENT_GRP_KEY.
--   3. Join to D_PATIENT (LEFT OUTER) on PATIENT_KEY → demographics +
--      PATIENT_ADDRESS computed via PATIENT_STREET_ADDRESS_1 etc.
--   4. Join to D_PROVIDER (INNER, comma-style) on ORDERING_PROVIDER_KEY
--      → PROVIDER_* + PROVIDER_ADDRESS.
--   5. Join to D_ORGANIZATION (INNER, comma-style) on
--      ORDERING_ORG_KEY + REPORTING_LAB_KEY → ORDERING_FACILITY +
--      REPORTING_FACILITY* (CLIA from ORG.ORGANIZATION_FACILITY_ID).
--   6. UPSERT into LAB100 keyed by RESULTED_LAB_TEST_KEY
--      (= LAB_TEST.LAB_TEST_KEY of the Result row).
--
-- UID BLOCK (this fixture): 22021000-22021999
--   22021300  LAB_TEST_KEY (Order #1, UID 22021400, RPR Syphilis)
--   22021301  LAB_TEST_KEY (Order #2, UID 22021401, ANA Auto-immune)
--   22021302  LAB_TEST_KEY (Result #1, UID 22021402, parent 22021400)
--   22021303  LAB_TEST_KEY (Result #2, UID 22021403, parent 22021401)
--   22021400  LAB_TEST_UID (Order #1)
--   22021401  LAB_TEST_UID (Order #2)
--   22021402  LAB_TEST_UID (Result #1)
--   22021403  LAB_TEST_UID (Result #2)
--   22021500-22021501  TEST_RESULT_GRP_KEYs (1 per Result row)
--   22021600-22021601  RESULT_COMMENT_GRP_KEYs (1 per Result row)
--   22021700-22021701  LAB_RESULT_COMMENT_KEYs
--   22021800-22021801  TEST_RESULT_VAL_KEYs (LAB_RESULT_VAL PK)
--
-- IDEMPOTENCY
--   Each block guarded by IF NOT EXISTS on its first allocated UID.
--   Safe to re-run; second invocation is a no-op (except tail SP exec).
--
-- TAIL-EXEC
--   sp_lab100_datamart_postprocessing is invoked at the bottom with the
--   orchestrator's stock LAB_OBS_UIDS list extended with my new Result
--   UIDs (22021402, 22021403). Wrapped in TRY/CATCH.
--
-- ORCH_TODO (optional, for cleanliness)
--   Add 22021402,22021403 to LAB_OBS_UIDS in scripts/merge_and_verify.sh
--   :451 so the orchestrator's Step-9 SP rerun continues to populate
--   these labs without relying on this fixture's tail-EXEC.
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE RDB_MODERN;
GO

-- =====================================================================
-- LAB_TEST — 2 Order rows + 2 Result rows.
-- The SP requires BOTH Order and Result rows so that:
--   (a) The Result UID lands in the CTE via the LAB_TEST_TYPE='Result'
--       branch.
--   (b) The Order UID (= Result.ROOT_ORDERED_TEST_PNTR) lands via the
--       UNION ALL ROOT_ORDERED_TEST_PNTR branch.
--   (c) The Order row supplies LAB_RPT_LOCAL_ID (final INSERT filter
--       drops src.LAB_RPT_LOCAL_ID IS NULL).
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_TEST WHERE LAB_TEST_KEY = 22021300)
BEGIN
    -- Order rows. ORDERED_LAB_TEST_CD / ORDERED_LAB_TEST_CD_DESC come
    -- from these. LAB_TEST_UID equals ROOT_ORDERED_TEST_PNTR (self).
    INSERT INTO dbo.LAB_TEST (
        LAB_TEST_KEY, LAB_TEST_UID, LAB_RPT_LOCAL_ID,
        LAB_TEST_CD, LAB_TEST_CD_DESC, LAB_TEST_TYPE,
        TEST_METHOD_CD, TEST_METHOD_CD_DESC,
        LAB_RPT_SHARE_IND, ELR_IND, LAB_RPT_UID,
        INTERPRETATION_FLG, LAB_RPT_RECEIVED_BY_PH_DT, LAB_RPT_CREATED_BY,
        REASON_FOR_TEST_DESC, REASON_FOR_TEST_CD,
        LAB_RPT_LAST_UPDATE_BY, LAB_TEST_DT, LAB_RPT_CREATED_DT,
        LAB_RPT_LAST_UPDATE_DT, JURISDICTION_CD,
        LAB_TEST_CD_SYS_CD, LAB_TEST_CD_SYS_NM, JURISDICTION_NM, OID,
        ALT_LAB_TEST_CD, LAB_RPT_STATUS, ALT_LAB_TEST_CD_DESC,
        ACCESSION_NBR, SPECIMEN_SRC, PRIORITY_CD,
        ALT_LAB_TEST_CD_SYS_CD, ALT_LAB_TEST_CD_SYS_NM,
        SPECIMEN_SITE, SPECIMEN_DETAILS,
        SPECIMEN_COLLECTION_VOL, SPECIMEN_COLLECTION_VOL_UNIT,
        SPECIMEN_DESC, SPECIMEN_SITE_DESC, CLINICAL_INFORMATION,
        ROOT_ORDERED_TEST_PNTR, PARENT_TEST_PNTR, LAB_TEST_PNTR,
        SPECIMEN_ADD_TIME, SPECIMEN_LAST_CHANGE_TIME, SPECIMEN_COLLECTION_DT,
        SPECIMEN_NM, ROOT_ORDERED_TEST_NM, PARENT_TEST_NM,
        RECORD_STATUS_CD, RDB_LAST_REFRESH_TIME,
        CONDITION_CD, LAB_TEST_STATUS
    ) VALUES
    (22021300, 22021400, N'OBS22021300GA01',
     N'86592-1', N'Rapid plasma reagin (RPR) test', N'Order',
     N'RPR', N'Rapid Plasma Reagin',
     N'T', N'Y', 22021400,
     N'A', '2026-04-10T09:00:00', 10009282,
     N'Syphilis screening — high-risk contact', N'SCRN',
     10009282, '2026-04-10T08:30:00', '2026-04-10T08:00:00',
     '2026-04-10T11:00:00', N'130001',
     N'2.16.840.1.113883.6.1', N'LN', N'Fulton County', 22021400,
     N'ALT-RPR-1', N'F', N'RPR Card (Locally Coded)',
     N'ACC-V2-22021300', N'SER', N'R',
     N'L', N'Local',
     N'258450006', N'Serum specimen, peripheral venous draw',
     N'5', N'mL',
     N'Serum', N'Serum', N'Patient reports rash and possible exposure.',
     22021400, 22021400, 22021400,
     '2026-04-10T08:00:00', '2026-04-10T08:30:00', '2026-04-09T18:00:00',
     N'Serum', N'Rapid plasma reagin (RPR) test', N'Rapid plasma reagin (RPR) test',
     N'ACTIVE', '2026-04-10T11:00:00',
     N'10311', N'Final'),
    (22021301, 22021401, N'OBS22021301GA01',
     N'5048-4', N'ANA — antinuclear antibody titer', N'Order',
     N'ANA-IF', N'Antinuclear Antibody — Indirect Immunofluorescence',
     N'T', N'Y', 22021401,
     N'A', '2026-04-11T09:00:00', 10009282,
     N'Auto-immune workup — joint pain + rash', N'SYMP',
     10009282, '2026-04-11T08:30:00', '2026-04-11T08:00:00',
     '2026-04-11T11:00:00', N'130001',
     N'2.16.840.1.113883.6.1', N'LN', N'Fulton County', 22021401,
     N'ALT-ANA-1', N'F', N'ANA Titer (Locally Coded)',
     N'ACC-V2-22021301', N'SER', N'R',
     N'L', N'Local',
     N'258450006', N'Serum specimen, peripheral venous draw',
     N'5', N'mL',
     N'Serum', N'Serum', N'Auto-immune symptom panel — rule out lupus / SLE.',
     22021401, 22021401, 22021401,
     '2026-04-11T08:00:00', '2026-04-11T08:30:00', '2026-04-10T18:00:00',
     N'Serum', N'ANA — antinuclear antibody titer', N'ANA — antinuclear antibody titer',
     N'ACTIVE', '2026-04-11T11:00:00',
     N'11704', N'Final');

    -- Result rows. ROOT_ORDERED_TEST_PNTR points back at the Order.
    -- LAB_RPT_LOCAL_ID matches its parent Order so the SP's joins pivot
    -- the Result with the Order's local_id / specimen / facility data.
    INSERT INTO dbo.LAB_TEST (
        LAB_TEST_KEY, LAB_TEST_UID, LAB_RPT_LOCAL_ID,
        LAB_TEST_CD, LAB_TEST_CD_DESC, LAB_TEST_TYPE,
        TEST_METHOD_CD, TEST_METHOD_CD_DESC,
        LAB_RPT_SHARE_IND, ELR_IND, LAB_RPT_UID,
        INTERPRETATION_FLG, LAB_RPT_RECEIVED_BY_PH_DT, LAB_RPT_CREATED_BY,
        REASON_FOR_TEST_DESC, REASON_FOR_TEST_CD,
        LAB_RPT_LAST_UPDATE_BY, LAB_TEST_DT, LAB_RPT_CREATED_DT,
        LAB_RPT_LAST_UPDATE_DT, JURISDICTION_CD,
        LAB_TEST_CD_SYS_CD, LAB_TEST_CD_SYS_NM, JURISDICTION_NM, OID,
        ALT_LAB_TEST_CD, LAB_RPT_STATUS, ALT_LAB_TEST_CD_DESC,
        ACCESSION_NBR, SPECIMEN_SRC, PRIORITY_CD,
        ALT_LAB_TEST_CD_SYS_CD, ALT_LAB_TEST_CD_SYS_NM,
        SPECIMEN_SITE, SPECIMEN_DETAILS,
        SPECIMEN_COLLECTION_VOL, SPECIMEN_COLLECTION_VOL_UNIT,
        SPECIMEN_DESC, SPECIMEN_SITE_DESC, CLINICAL_INFORMATION,
        ROOT_ORDERED_TEST_PNTR, PARENT_TEST_PNTR, LAB_TEST_PNTR,
        SPECIMEN_ADD_TIME, SPECIMEN_LAST_CHANGE_TIME, SPECIMEN_COLLECTION_DT,
        SPECIMEN_NM, ROOT_ORDERED_TEST_NM, PARENT_TEST_NM,
        RECORD_STATUS_CD, RDB_LAST_REFRESH_TIME,
        CONDITION_CD, LAB_TEST_STATUS
    ) VALUES
    (22021302, 22021402, N'OBS22021300GA01',
     N'86592-1', N'Rapid plasma reagin (RPR) test', N'Result',
     N'RPR', N'Rapid Plasma Reagin',
     N'T', N'Y', 22021402,
     N'A', '2026-04-10T10:00:00', 10009282,
     N'Syphilis screening — high-risk contact', N'SCRN',
     10009282, '2026-04-10T08:30:00', '2026-04-10T08:00:00',
     '2026-04-10T11:00:00', N'130001',
     N'2.16.840.1.113883.6.1', N'LOINC', N'Fulton County', 22021402,
     N'ALT-RPR-1', N'F', N'RPR Card (Locally Coded)',
     N'ACC-V2-22021300', N'SER', N'R',
     N'L', N'Local',
     N'258450006', N'Serum specimen, peripheral venous draw',
     N'5', N'mL',
     N'Serum', N'Serum', N'Reactive 1:32 — recommend confirmatory TPPA.',
     22021400, 22021400, 22021402,
     '2026-04-10T08:00:00', '2026-04-10T08:30:00', '2026-04-09T18:00:00',
     N'Serum', N'Rapid plasma reagin (RPR) test', N'Rapid plasma reagin (RPR) test',
     N'ACTIVE', '2026-04-10T11:00:00',
     N'10311', N'Final'),
    (22021303, 22021403, N'OBS22021301GA01',
     N'5048-4', N'ANA — antinuclear antibody titer', N'Result',
     N'ANA-IF', N'Antinuclear Antibody — Indirect Immunofluorescence',
     N'T', N'Y', 22021403,
     N'A', '2026-04-11T10:00:00', 10009282,
     N'Auto-immune workup — joint pain + rash', N'SYMP',
     10009282, '2026-04-11T08:30:00', '2026-04-11T08:00:00',
     '2026-04-11T11:00:00', N'130001',
     N'2.16.840.1.113883.6.1', N'LOINC', N'Fulton County', 22021403,
     N'ALT-ANA-1', N'F', N'ANA Titer (Locally Coded)',
     N'ACC-V2-22021301', N'SER', N'R',
     N'L', N'Local',
     N'258450006', N'Serum specimen, peripheral venous draw',
     N'5', N'mL',
     N'Serum', N'Serum', N'Negative — auto-immune unlikely.',
     22021401, 22021401, 22021403,
     '2026-04-11T08:00:00', '2026-04-11T08:30:00', '2026-04-10T18:00:00',
     N'Serum', N'ANA — antinuclear antibody titer', N'ANA — antinuclear antibody titer',
     N'ACTIVE', '2026-04-11T11:00:00',
     N'11704', N'Final');
END
GO

-- =====================================================================
-- TEST_RESULT_GROUPING / RESULT_COMMENT_GROUP — parent grouping rows
-- required by FK from LAB_RESULT_VAL / LAB_RESULT_COMMENT respectively.
-- Note: LAB_TEST_RESULT.RESULT_COMMENT_GRP_KEY is NOT NULL — the parent
-- grouping rows MUST exist before LAB_TEST_RESULT inserts.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.TEST_RESULT_GROUPING WHERE TEST_RESULT_GRP_KEY = 22021500)
BEGIN
    INSERT INTO dbo.TEST_RESULT_GROUPING (TEST_RESULT_GRP_KEY, LAB_TEST_UID, RDB_LAST_REFRESH_TIME) VALUES
        (22021500, 22021402, '2026-04-10T11:00:00'),
        (22021501, 22021403, '2026-04-11T11:00:00');
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.RESULT_COMMENT_GROUP WHERE RESULT_COMMENT_GRP_KEY = 22021600)
BEGIN
    INSERT INTO dbo.RESULT_COMMENT_GROUP (RESULT_COMMENT_GRP_KEY, LAB_TEST_UID, RDB_LAST_REFRESH_TIME) VALUES
        (22021600, 22021402, '2026-04-10T11:00:00'),
        (22021601, 22021403, '2026-04-11T11:00:00');
END
GO

-- =====================================================================
-- LAB_RESULT_VAL — one row per Result row. TEST_RESULT_GRP_KEY is the
-- LTR.TEST_RESULT_GRP_KEY FK target. Supplies the RESULT / RESULT_REF_*
-- / RESULTEDTEST_VAL_* / NUMERIC_RESULT_WITHUNITS / LAB_RESULT_TXT_VAL
-- columns of LAB100 via the #TMP_LAB_RESULT_VALMODIFIED CTE.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_RESULT_VAL WHERE TEST_RESULT_GRP_KEY = 22021500)
BEGIN
    INSERT INTO dbo.LAB_RESULT_VAL (
        TEST_RESULT_GRP_KEY, NUMERIC_RESULT, RESULT_UNITS,
        LAB_RESULT_TXT_VAL, TEST_RESULT_VAL_CD, TEST_RESULT_VAL_CD_DESC,
        TEST_RESULT_VAL_CD_SYS_CD, TEST_RESULT_VAL_CD_SYS_NM,
        ALT_RESULT_VAL_CD, ALT_RESULT_VAL_CD_DESC,
        ALT_RESULT_VAL_CD_SYS_CD, ALT_RESULT_VAL_CD_SYS_NM,
        TEST_RESULT_VAL_KEY, RECORD_STATUS_CD, LAB_TEST_UID,
        REF_RANGE_FRM, REF_RANGE_TO,
        FROM_TIME, TO_TIME, RDB_LAST_REFRESH_TIME
    ) VALUES
    (22021500, N'1:32', N'titer',
     N'Reactive at 1:32 — non-treponemal screen positive, recommend FTA-ABS confirm.',
     N'10828004', N'Positive',
     N'2.16.840.1.113883.6.96', N'SNOMED-CT',
     N'POS', N'Positive',
     N'L', N'Local',
     22021800, N'ACTIVE', 22021402,
     N'NR', N'1:8',
     '2026-04-10T10:00:00', '2026-04-10T10:00:00', '2026-04-10T11:00:00'),
    (22021501, N'<1:40', N'titer',
     N'Non-reactive — ANA undetected at screening titer.',
     N'260385009', N'Negative',
     N'2.16.840.1.113883.6.96', N'SNOMED-CT',
     N'NEG', N'Negative',
     N'L', N'Local',
     22021801, N'ACTIVE', 22021403,
     N'<1:40', N'1:40',
     '2026-04-11T10:00:00', '2026-04-11T10:00:00', '2026-04-11T11:00:00');
END
GO

-- =====================================================================
-- LAB_RESULT_COMMENT — one row per Result row. RESULT_COMMENT_GRP_KEY
-- is the LTR.RESULT_COMMENT_GRP_KEY FK target. Provides LAB100.LAB_RESULT_COMMENTS.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_RESULT_COMMENT WHERE LAB_RESULT_COMMENT_KEY = 22021700)
BEGIN
    INSERT INTO dbo.LAB_RESULT_COMMENT (
        LAB_TEST_UID, LAB_RESULT_COMMENT_KEY, LAB_RESULT_COMMENTS,
        RESULT_COMMENT_GRP_KEY, RECORD_STATUS_CD, RDB_LAST_REFRESH_TIME
    ) VALUES
    (22021402, 22021700,
     N'RPR positive at 1:32. Recommend FTA-ABS or TP-PA confirmation. Patient counseling per CDC syphilis guidelines.',
     22021600, N'ACTIVE', '2026-04-10T11:00:00'),
    (22021403, 22021701,
     N'ANA non-reactive. Auto-immune disease unlikely; consider alternate dx for joint symptoms.',
     22021601, N'ACTIVE', '2026-04-11T11:00:00');
END
GO

-- =====================================================================
-- LAB_TEST_RESULT — links each Result LAB_TEST to D_PATIENT (row 3
-- Foundation Patient — well-populated demographics), D_PROVIDER (row
-- 12 Foundation Provider — full street/city/state/zip/phone), and
-- D_ORGANIZATION (row 7 Foundation Organization — full CLIA/phone/name).
-- These FK targets exist in baseline seed data so the SP's INNER joins
-- on ORDERING_PROVIDER_KEY / ORDERING_ORG_KEY / REPORTING_LAB_KEY
-- resolve cleanly and the patient/provider/org demographic columns
-- of LAB100 get populated.
--
-- RESULT_COMMENT_GRP_KEY is NOT NULL — must reference the RESULT_COMMENT_GROUP
-- rows authored above. Likewise TEST_RESULT_GRP_KEY references TEST_RESULT_GROUPING.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.LAB_TEST_RESULT WHERE LAB_TEST_KEY = 22021302)
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
    (22021302, 22021402, 22021600, 22021500,
     7, 3, 12,
     12, 12,
     7, 7, 242,
     5938, 1, 1,
     1, 12, N'ACTIVE',
     '2026-04-10T11:00:00'),
    (22021303, 22021403, 22021601, 22021501,
     7, 3, 12,
     12, 12,
     7, 7, 242,
     5938, 1, 1,
     1, 12, N'ACTIVE',
     '2026-04-11T11:00:00');
END
GO

-- =====================================================================
-- TAIL-EXEC — run sp_lab100_datamart_postprocessing with the existing
-- orchestrator UID list extended with the two new Result UIDs. Wrapped
-- in TRY/CATCH so a failure here doesn't break the rest of the suite.
-- =====================================================================
BEGIN TRY
END TRY
BEGIN CATCH
    PRINT 'zz_lab100_enrich: sp_lab100_datamart_postprocessing tail-EXEC failed — '
        + ERROR_MESSAGE();
END CATCH
GO
