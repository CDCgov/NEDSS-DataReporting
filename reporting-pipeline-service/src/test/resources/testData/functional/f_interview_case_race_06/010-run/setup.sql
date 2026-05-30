-- One of 10 parallel functional tests for the F_INTERVIEW_CASE duplicate-insert race.
-- Each copy seeds a different INTERVIEW_UID mapped to the same D_INTERVIEW_KEY
-- (1000010000) and calls sp_f_interview_case_postprocessing. The functional test
-- runner executes these concurrently. With the patch, all calls produce exactly
-- one row. Without it, the race produces duplicates and the COUNT exceeds 1.

USE RDB_MODERN;

SET IDENTITY_INSERT dbo.nrt_interview_key ON;
INSERT INTO dbo.nrt_interview_key (d_interview_key, interview_uid, created_dttm, updated_dttm)
VALUES (1000010000, 1000010006, SYSDATETIME(), SYSDATETIME());
SET IDENTITY_INSERT dbo.nrt_interview_key OFF;

EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'1000010006', @debug = 0;
