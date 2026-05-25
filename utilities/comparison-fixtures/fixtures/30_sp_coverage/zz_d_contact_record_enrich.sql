-- =====================================================================
-- Tier 3 — Enrich d_contact_record (target: 42/66 → 60+/66)
-- =====================================================================
-- Authored 2026-05-24 (overnight loop round-2 top-up, Agent U).
--
-- SP signature:
--   dbo.sp_d_contact_record_postprocessing
--     @contact_uids NVARCHAR(MAX),  -- comma-separated contact UIDs
--     @debug        bit = 'false'
--
-- The SP's hardcoded UPDATE/INSERT writes ~40 nrt_contact columns
-- straight into dbo.D_CONTACT_RECORD. The remaining D_CONTACT_RECORD
-- columns (CTT_EXPOSURE_TYPE, CTT_HEIGHT, CR_CONTACT1, etc.) only flow
-- in through the *dynamic* PIVOT branch keyed on dbo.NRT_METADATA_COLUMNS.
--
-- Baseline (3 contacts: 20000170, 20120010, 22011000 after the SP runs):
--   * 42/66 cols populated (≥1 row non-NULL)
--   * 24/66 cols populated NOWHERE — every one of these is a "dynamic"
--     column whose value the SP expects to read from NRT_CONTACT_ANSWER
--     via the pivot, and dbo.NRT_METADATA_COLUMNS is empty for
--     TABLE_NAME='D_CONTACT_RECORD' so the pivot branch never fires.
--
-- The 24 fully-NULL columns (verified via INFORMATION_SCHEMA.COLUMNS):
--   TREATMNT_END_DESCRIPTION,
--   CTT_INITIATE_FOLLOWUP_DT,
--   CTT_LAST_SEX_EXP_DT,        CTT_FIRST_SEX_EXP_DT,
--   CTT_LAST_NDLSHARE_EXP_DT,   CTT_FIRST_NDLSHARE_EXP_DT,
--   CTT_REL_WITH_PATIENT,
--   CTT_ELICIT_INTERNET_INFO,   CTT_MET_OP_INTERNET, CTT_SPOUSE_OF_OP,
--   CTT_SOURCE_SPREAD,
--   CTT_HEIGHT, CTT_SIZE_BUILD, CTT_OTHER_ID_INFO,
--   CTT_HAIR, CTT_COMPLEXION,
--   CTT_SEX_EXP_FREQ, CTT_NDLSHARE_EXP_FREQ,
--   CTT_EXPOSURE_TYPE, CTT_EXPOSURE_SITE_TYPE,
--   CTT_FIRST_EXPOSURE_DT, CTT_LAST_EXPOSURE_DT,
--   CR_CONTACT1, CR_CONTACT2.
--
-- Strategy:
--   (1) Seed dbo.NRT_METADATA_COLUMNS with a row per dynamic column so
--       the SP's PIVOT branch fires. The SP only ALTERs the table for
--       column names NOT already in INFORMATION_SCHEMA.COLUMNS, so
--       seeding metadata for already-existing columns simply enrolls
--       them into the pivot SELECT-list (no DDL fired).
--   (2) INSERT into dbo.NRT_CONTACT_ANSWER for contact_uid=22011000
--       (the COVID contact authored in zz_covid_contact.sql) with
--       rdb_column_nm = each target column and a reasonable answer_val.
--       Idempotent guards skip rows that already exist (4 are pre-seeded
--       by zz_covid_contact.sql: CTT_EXPOSURE_TYPE, CTT_EXPOSURE_SITE_TYPE,
--       CTT_FIRST_EXPOSURE_DT, CTT_LAST_EXPOSURE_DT).
--   (3) Tail-EXEC sp_d_contact_record_postprocessing to repopulate.
--
-- Sort order: file prefixed `zz_` to apply after `zz_covid_contact.sql`
-- (whose contact UID 22011000 we enrich here).
--
-- UID block: 22027000-22027999 reserved for Agent U. No new contact rows
-- are needed — we enrich the existing contact 22011000 only — so this
-- fixture does not actually consume any UIDs from the block.
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- (1) Register the 22 dynamic-pivot columns in NRT_METADATA_COLUMNS.
--     Each column already exists on D_CONTACT_RECORD so the SP's ALTER
--     TABLE step skips the DDL — these rows just enroll the columns
--     into the dynamic PIVOT branch.
--
--     CR_CONTACT1 and CR_CONTACT2 are intentionally OMITTED: they are
--     fed by the legacy *_FOLLOWUP_* CR path used by a different SP
--     (sp_covid_contact_datamart_postprocessing) — d_contact_record's
--     SP has no straight column ⇆ answer mapping for them, but for
--     defensive coverage we still register them so pivot will pick them
--     up when matching answer rows exist.
-- ---------------------------------------------------------------------
DECLARE @ContactRecCols TABLE (col_nm VARCHAR(128) PRIMARY KEY);
INSERT INTO @ContactRecCols (col_nm) VALUES
    (N'TREATMNT_END_DESCRIPTION'),
    (N'CTT_INITIATE_FOLLOWUP_DT'),
    (N'CTT_LAST_SEX_EXP_DT'),
    (N'CTT_FIRST_SEX_EXP_DT'),
    (N'CTT_LAST_NDLSHARE_EXP_DT'),
    (N'CTT_FIRST_NDLSHARE_EXP_DT'),
    (N'CTT_REL_WITH_PATIENT'),
    (N'CTT_ELICIT_INTERNET_INFO'),
    (N'CTT_MET_OP_INTERNET'),
    (N'CTT_SPOUSE_OF_OP'),
    (N'CTT_SOURCE_SPREAD'),
    (N'CTT_HEIGHT'),
    (N'CTT_SIZE_BUILD'),
    (N'CTT_OTHER_ID_INFO'),
    (N'CTT_HAIR'),
    (N'CTT_COMPLEXION'),
    (N'CTT_SEX_EXP_FREQ'),
    (N'CTT_NDLSHARE_EXP_FREQ'),
    (N'CTT_EXPOSURE_TYPE'),
    (N'CTT_EXPOSURE_SITE_TYPE'),
    (N'CTT_FIRST_EXPOSURE_DT'),
    (N'CTT_LAST_EXPOSURE_DT'),
    (N'CR_CONTACT1'),
    (N'CR_CONTACT2');

INSERT INTO dbo.NRT_METADATA_COLUMNS (TABLE_NAME, RDB_COLUMN_NM, LAST_CHG_TIME, LAST_CHG_USER_ID)
SELECT N'D_CONTACT_RECORD', c.col_nm, GETDATE(), 10009282
FROM @ContactRecCols c
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.NRT_METADATA_COLUMNS m
    WHERE m.TABLE_NAME = 'D_CONTACT_RECORD'
      AND m.RDB_COLUMN_NM = c.col_nm
);
GO

-- ---------------------------------------------------------------------
-- (2) Insert NRT_CONTACT_ANSWER rows for contact_uid=22011000 covering
--     each dynamic column. The 4 rows from zz_covid_contact.sql
--     (CTT_EXPOSURE_TYPE / CTT_EXPOSURE_SITE_TYPE /
--     CTT_FIRST_EXPOSURE_DT / CTT_LAST_EXPOSURE_DT) are skipped by the
--     idempotency guard.
--
--     Values chosen to be plausible for a COVID contact-trace scenario.
-- ---------------------------------------------------------------------
DECLARE @ContactAnswers TABLE (rdb_column_nm VARCHAR(128) PRIMARY KEY, answer_val VARCHAR(2000));
INSERT INTO @ContactAnswers (rdb_column_nm, answer_val) VALUES
    (N'TREATMNT_END_DESCRIPTION',   N'Treatment course completed; no follow-up required'),
    (N'CTT_INITIATE_FOLLOWUP_DT',   N'2026-04-04'),
    (N'CTT_LAST_SEX_EXP_DT',        N'2026-03-30'),
    (N'CTT_FIRST_SEX_EXP_DT',       N'2026-03-25'),
    (N'CTT_LAST_NDLSHARE_EXP_DT',   N'2026-03-29'),
    (N'CTT_FIRST_NDLSHARE_EXP_DT',  N'2026-03-22'),
    (N'CTT_REL_WITH_PATIENT',       N'Spouse'),
    (N'CTT_ELICIT_INTERNET_INFO',   N'N'),
    (N'CTT_MET_OP_INTERNET',        N'N'),
    (N'CTT_SPOUSE_OF_OP',           N'Y'),
    (N'CTT_SOURCE_SPREAD',          N'Source'),
    (N'CTT_HEIGHT',                 N'5ft 10in'),
    (N'CTT_SIZE_BUILD',             N'Medium'),
    (N'CTT_OTHER_ID_INFO',          N'Tattoo on left forearm'),
    (N'CTT_HAIR',                   N'Brown'),
    (N'CTT_COMPLEXION',             N'Fair'),
    (N'CTT_SEX_EXP_FREQ',           N'Weekly'),
    (N'CTT_NDLSHARE_EXP_FREQ',      N'Never'),
    (N'CR_CONTACT1',                N'CR-CONTACT-A'),
    (N'CR_CONTACT2',                N'CR-CONTACT-B');

INSERT INTO dbo.NRT_CONTACT_ANSWER (contact_uid, rdb_column_nm, answer_val, answer_code)
SELECT 22011000, a.rdb_column_nm, a.answer_val, NULL
FROM @ContactAnswers a
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.NRT_CONTACT_ANSWER e
    WHERE e.contact_uid = 22011000
      AND e.rdb_column_nm = a.rdb_column_nm
);
GO

-- ---------------------------------------------------------------------
-- (3) Tail-EXEC the SP for all three known contact UIDs so the dynamic
--     pivot fires and the previously-NULL columns populate.
--     Wrapped in TRY/CATCH so a SP failure doesn't block other fixtures.
-- ---------------------------------------------------------------------
BEGIN TRY
    EXEC dbo.sp_d_contact_record_postprocessing
        @contact_uids = N'20000170,20120010,22011000',
        @debug        = 'false';
END TRY
BEGIN CATCH
    PRINT 'sp_d_contact_record_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO
