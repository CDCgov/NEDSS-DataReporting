USE [RDB_MODERN];

-- Bug #8 regression test: the per-condition LDF datamart post-processing SPs
-- must not emit a Msg 537 ("Invalid length parameter passed to LEFT or
-- SUBSTRING") when their LDF_* table only has its baseline-key columns (i.e.
-- no dynamic LDF answer columns have been added yet). This is the
-- freshly-applied liquibase state for those per-condition LDF tables --
-- exactly the state this test reproduces.
--
-- The fix wraps the trailing-comma-stripping SUBSTRING(@dynamiccolumnUpdate,
-- 1, LEN(@dynamiccolumnUpdate)-1) idiom in
-- IF @dynamiccolumnUpdate IS NOT NULL AND @dynamiccolumnUpdate <> ''.
-- The same fix was applied to all 6 per-condition LDF SPs, so we exercise
-- each one here rather than relying on tetanus as a representative case.
--
-- Args are passed positionally because the first parameter is named
-- @phc_id_list in some SPs and @phc_uids in others; @debug is the bit.

EXEC dbo.sp_ldf_bmird_datamart_postprocessing                    N'22000200', 0;
EXEC dbo.sp_ldf_foodborne_datamart_postprocessing                N'22000200', 0;
EXEC dbo.sp_ldf_mumps_datamart_postprocessing                    N'22000200', 0;
EXEC dbo.sp_ldf_tetanus_datamart_postprocessing                  N'22000200', 0;
EXEC dbo.sp_ldf_vaccine_prevent_diseases_datamart_postprocessing N'22000200', 0;
EXEC dbo.sp_ldf_hepatitis_datamart_postprocessing                N'22000200', 0;
