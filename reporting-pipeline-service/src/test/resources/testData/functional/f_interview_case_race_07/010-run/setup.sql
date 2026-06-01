-- One of 10 parallel functional tests for the F_INTERVIEW_CASE duplicate-insert race.
-- All 10 copies share INTERVIEW_UID 1000010099 mapping to D_INTERVIEW_KEY 1000010000.
-- Whichever test wins the race seeds the nrt_interview_key row; the others see
-- the row already there (via IF NOT EXISTS) or, in the tiny check-vs-insert gap,
-- hit the PK and TRY/CATCH swallows it. All 10 then call the SP for the same
-- UID, racing INSERTs against F_INTERVIEW_CASE (which has no UNIQUE constraint).
-- With the patch, UPDLOCK + HOLDLOCK serializes the inserts → exactly one row.
-- Without the patch, the race fires and the COUNT exceeds 1.

USE RDB_MODERN;

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_interview_key WHERE d_interview_key = 1000010000)
BEGIN
    SET IDENTITY_INSERT dbo.nrt_interview_key ON;
    BEGIN TRY
        INSERT INTO dbo.nrt_interview_key (d_interview_key, interview_uid, created_dttm, updated_dttm)
        VALUES (1000010000, 1000010099, SYSDATETIME(), SYSDATETIME());
    END TRY
    BEGIN CATCH
        -- Lost the race after the IF NOT EXISTS check; row is already there.
    END CATCH;
    SET IDENTITY_INSERT dbo.nrt_interview_key OFF;
END;

EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'1000010099', @debug = 0;
