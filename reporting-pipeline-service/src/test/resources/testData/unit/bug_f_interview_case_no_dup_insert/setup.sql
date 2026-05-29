-- Regression test for the F_INTERVIEW_CASE duplicate-insert race.
-- Pre-seeds a row with key 49000099 (simulating "another session already
-- inserted this key"), then runs sp_f_interview_case_postprocessing for
-- the same UID. The SP should detect the existing row via its existence
-- check and route to the UPDATE branch instead of double-inserting.
-- query.sql asserts exactly one row remains for that key.
--
-- Note: single-threaded execution cannot reproduce the actual concurrent
-- race the patch closes (UPDLOCK + HOLDLOCK behaves identically to plain
-- NOT IN under one session). This test pins the "pre-existing row →
-- UPDATE, not INSERT" contract that a future refactor could break.

USE RDB_MODERN;

SET IDENTITY_INSERT dbo.nrt_interview_key ON;
INSERT INTO dbo.nrt_interview_key (d_interview_key, interview_uid, created_dttm, updated_dttm)
VALUES (49000099, 49000099, SYSDATETIME(), SYSDATETIME());
SET IDENTITY_INSERT dbo.nrt_interview_key OFF;

INSERT INTO dbo.F_INTERVIEW_CASE
    (D_INTERVIEW_KEY, PATIENT_KEY, IX_INTERVIEWER_KEY, INVESTIGATION_KEY,
     INTERPRETER_KEY, PHYSICIAN_KEY, NURSE_KEY, PROXY_KEY,
     IX_INTERVIEWEE_KEY, INTERVENTION_SITE_KEY)
VALUES (49000099, 1, 1, 1, 1, 1, 1, 1, 1, 1);

EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'49000099', @debug = 0;
