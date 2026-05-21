-- Regression test for RTR bug #4:
-- sp_nrt_provider_postprocessing previously referenced a non-existent temp
-- table #PATIENT_UPDATE_LIST instead of #PROVIDER_UPDATE_LIST at line 564.
-- The typo only fired when the SP ran against an already-loaded UID whose
-- staging row in nrt_provider differed from D_PROVIDER on any tracked
-- column. Before the fix the SP aborted with Msg 208 inside its open
-- BEGIN TRANSACTION; after the fix it should update D_PROVIDER cleanly.
--
-- Setup seeds an existing D_PROVIDER row and a matching nrt_provider row
-- that differs in several tracked columns, then calls the SP. The query.sql
-- asserts D_PROVIDER reflects the new values.

USE RDB_MODERN;

SET IDENTITY_INSERT dbo.nrt_provider_key ON;
INSERT INTO dbo.nrt_provider_key (d_provider_key, provider_uid, created_dttm, updated_dttm)
VALUES (49000004, 49000004, SYSDATETIME(), SYSDATETIME());
SET IDENTITY_INSERT dbo.nrt_provider_key OFF;

INSERT INTO dbo.D_PROVIDER (PROVIDER_UID, PROVIDER_KEY, PROVIDER_LAST_NAME, PROVIDER_FIRST_NAME, PROVIDER_CITY, PROVIDER_STATE, PROVIDER_ZIP, PROVIDER_QUICK_CODE)
VALUES (49000004, 49000004, N'OldName', N'OldFirst', N'OldCity', N'OldState', N'00000', N'OQC');

INSERT INTO dbo.nrt_provider (provider_uid, last_name, first_name, city, state, zip, quick_code)
VALUES (49000004, N'NewName', N'NewFirst', N'NewCity', N'NewState', N'11111', N'NQC');

EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'49000004', @debug = 0;
