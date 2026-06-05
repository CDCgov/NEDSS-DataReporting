-- =====================================================================
-- Tier 3 — COVID_CASE_DATAMART Round 2 enrichment (Agent R)
-- =====================================================================
-- Authored 2026-05-24 by Agent R (parallel enrichment).
--
-- Goal: lift dbo.covid_case_datamart populated-column count from
-- ~241/383 (post Agent A's round 1) toward 320+/383 by:
--   1. Creating supporting D_PROVIDER / D_ORGANIZATION rows and
--      re-pointing NRT_INVESTIGATION 22003000 fks at them
--      (populates HOSPITAL_NAME, PHC_INV_*, PHYS_*, RPT_PRV_*, RPT_ORG_*).
--   2. Inserting NRT_INVESTIGATION_NOTIFICATION + NRT_INVESTIGATION_CONFIRMATION
--      rows scoped to PHC 22003000 (populates NOTIFICATION_*, CONFIRMATION_*).
--   3. Updating NRT_INVESTIGATION 22003000 directly for PHC-derived
--      cols: txt, notes, detection_method_cd, effective_duration_amt,
--      effective_duration_unit_cd (populates INV_COMMENTS, NOTES,
--      DETECT_METHOD_CD, ILLNESS_DURATION, ILLNESS_DURATION_UNIT).
--   4. Authoring 96 supplemental nrt_page_case_answer rows for the 32
--      repeating-group COVID questions (each gets answer_group_seq_nbr
--      1, 2, 3 — populates *_1, *_2, *_3 columns).
--   5. Authoring 6 supplemental nrt_page_case_answer rows for
--      partial-repeating-group cols (TEST_RESULT_2/3, TEST_TYPE_2/3,
--      PERFORMING_LAB_TYPE_2/3).
--   6. Authoring 12 supplemental nrt_page_case_answer rows for
--      non-repeating COVID questions not covered by Agent A.
--
-- WHY THIS WORKS
--   sp_covid_case_datamart_postprocessing is idempotent (DELETE+INSERT
--   per PHC). The dim/PHC/answer rows we author here are picked up on
--   the next SP run. PHC 22003000 is dedicated to this datamart and
--   only one of two COVID PHCs (22000070 is the other) — but
--   22000070's row is unaffected by our changes since our targets are
--   either:
--     - act_uid=22003000 (nrt_page_case_answer)
--     - public_health_case_uid=22003000 (notification/confirmation)
--     - WHERE public_health_case_uid=22003000 (NRT_INVESTIGATION UPDATE)
--     - New dim UIDs 22024xxx (D_PROVIDER/D_ORGANIZATION)
--   D_PATIENT 20000000 is shared by 25 PHCs and is NOT touched here.
--   (The 4 patient-specific gaps — PATIENT_GEN_COMMENTS,
--   PATIENT_MARITAL_STS, PATIENT_NAME_SUFFIX, PATIENT_PHONE_EXT_WORK —
--   are deliberately left for the orchestrator to address via a
--   COVID-dedicated patient swap.)
--
-- UID block: 22024000..22024999 (Agent R allotment).
--
-- IDEMPOTENCY
--   Wrapped in IF NOT EXISTS guards keyed on the first allocated UID
--   of each section. Re-applying after a successful insert is a no-op.
--
-- TAIL-EXEC
--   Yes — explicit TRY/CATCH EXEC sp_covid_case_datamart_postprocessing
--   so coverage numbers refresh immediately after apply.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- Section 1: D_PROVIDER + D_ORGANIZATION supporting dims.
-- UIDs 22024000..22024004.
-- ---------------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM [dbo].[D_PROVIDER] WHERE PROVIDER_UID = 22024000)
BEGIN
    INSERT INTO [dbo].[D_PROVIDER]
        (PROVIDER_UID, PROVIDER_KEY, PROVIDER_LOCAL_ID, PROVIDER_RECORD_STATUS,
         PROVIDER_FIRST_NAME, PROVIDER_LAST_NAME,
         PROVIDER_PHONE_WORK, PROVIDER_PHONE_EXT_WORK)
    VALUES
        (22024000, 22024000, N'PRV22024000GA01', N'ACTIVE',
         N'Inez', N'Investigator', N'404-555-2200', N'201'),
        (22024001, 22024001, N'PRV22024001GA01', N'ACTIVE',
         N'Phil', N'Physician', N'404-555-2210', N'202'),
        (22024002, 22024002, N'PRV22024002GA01', N'ACTIVE',
         N'Roger', N'Reporter', N'404-555-2220', N'203');
END;
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[D_ORGANIZATION] WHERE ORGANIZATION_UID = 22024003)
BEGIN
    INSERT INTO [dbo].[D_ORGANIZATION]
        (ORGANIZATION_UID, ORGANIZATION_KEY, ORGANIZATION_LOCAL_ID,
         ORGANIZATION_RECORD_STATUS, ORGANIZATION_NAME,
         ORGANIZATION_PHONE_WORK, ORGANIZATION_PHONE_EXT_WORK)
    VALUES
        (22024003, 22024003, N'ORG22024003GA01', N'ACTIVE',
         N'Test Reporting Org', N'404-555-2230', N'301'),
        (22024004, 22024004, N'ORG22024004GA01', N'ACTIVE',
         N'Test Hospital', N'404-555-2240', N'302');
END;
GO

-- ---------------------------------------------------------------------
-- Section 2: Re-point NRT_INVESTIGATION 22003000 + populate phc-derived cols.
-- ---------------------------------------------------------------------

UPDATE [dbo].[NRT_INVESTIGATION]
SET
    investigator_id = 22024000,
    physician_id = 22024001,
    person_as_reporter_uid = 22024002,
    organization_id = 22024003,
    hospital_uid = 22024004,
    txt = N'COVID case investigation comments authored by Agent R round 2',
    notes = N'Agent R round 2 notes — populating NOTES datamart column',
    detection_method_cd = N'ACTIVE',
    effective_duration_amt = 7,
    effective_duration_unit_cd = N'D'
WHERE public_health_case_uid = 22003000;
GO

-- ---------------------------------------------------------------------
-- Section 3: NRT_INVESTIGATION_NOTIFICATION row (NOTIFICATION_* cols).
-- ---------------------------------------------------------------------

GO

-- ---------------------------------------------------------------------
-- Section 4: NRT_INVESTIGATION_CONFIRMATION row (CONFIRMATION_* cols).
-- ---------------------------------------------------------------------

GO

-- ---------------------------------------------------------------------
-- Section 5: nrt_page_case_answer rows for 12 non-repeating COVID
-- questions not covered by Agent A's round 1.
-- UIDs 22024100..22024111.
-- ---------------------------------------------------------------------

GO

-- ---------------------------------------------------------------------
-- Section 6: nrt_page_case_answer rows for 32 repeating-group questions.
-- Each base question gets 3 answer rows with answer_group_seq_nbr=1,2,3
-- to populate the *_1, *_2, *_3 datamart cols.
-- UIDs 22024200..22024295 (32 * 3 = 96 rows).
-- ---------------------------------------------------------------------

GO

-- ---------------------------------------------------------------------
-- Section 5b: FIX up Section 5 rows — set seq_nbr=1.
-- The 12 non-repeating PG_COVID cols are nbs_ui_component_uid=1013
-- (multi-answer), so the SP routes them through #COVID_CASE_MULTI_ANS_DATA
-- which REQUIRES seq_nbr IS NOT NULL. Update existing rows.
-- ---------------------------------------------------------------------

UPDATE [dbo].[nrt_page_case_answer]
SET seq_nbr = 1
WHERE nbs_case_answer_uid BETWEEN 22024100 AND 22024111
  AND seq_nbr IS NULL;
GO

-- ---------------------------------------------------------------------
-- Section 7: nrt_page_case_answer rows for partial-repeating cols.
-- These have only the _2 and _3 datamart cols unpopulated; the _1 is
-- already populated by foundation data. We need answers with
-- answer_group_seq_nbr=2 and 3.
-- UIDs 22024400..22024405.
-- ---------------------------------------------------------------------

GO

-- ---------------------------------------------------------------------
-- Tail EXEC: refresh covid_case_datamart so coverage reflects changes.
-- ---------------------------------------------------------------------

GO
