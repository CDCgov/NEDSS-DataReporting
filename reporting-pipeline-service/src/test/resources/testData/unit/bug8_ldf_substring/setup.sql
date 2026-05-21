USE [RDB_MODERN];

-- Bug #8 regression test: sp_ldf_tetanus_datamart_postprocessing must not
-- emit a Msg 537 ("Invalid length parameter passed to LEFT or SUBSTRING")
-- when LDF_TETANUS only has its 7 baseline-key columns (i.e. no dynamic
-- LDF answer columns have been added yet). This is the freshly-applied
-- liquibase state for the per-condition LDF table -- exactly the state
-- this test reproduces.
--
-- The fix wraps the trailing-comma-stripping SUBSTRING(@dynamiccolumnUpdate,
-- 1, LEN(@dynamiccolumnUpdate)-1) idiom in
-- IF @dynamiccolumnUpdate IS NOT NULL AND @dynamiccolumnUpdate <> ''.
-- Tetanus is the representative case (the bug was originally surfaced
-- there); the same fix is applied to the 5 peer per-condition LDF SPs.

EXEC dbo.sp_ldf_tetanus_datamart_postprocessing
     @phc_id_list = N'22000200',
     @debug       = 0;
