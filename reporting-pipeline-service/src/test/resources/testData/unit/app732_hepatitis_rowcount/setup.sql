-- APP-732: sp_hepatitis_datamart_postprocessing step-3 row_count logging (APP-732).
-- The IF @debug SELECT once sat between SELECT INTO #TMP_F_PAGE_CASE and the
-- SELECT @ROWCOUNT_NO = @@ROWCOUNT capture, so with @debug=0 the predicate-only
-- IF reset @@ROWCOUNT to 0 and JOB_FLOW_LOG recorded row_count=0 even though the
-- temp table had rows. Fix reorders the capture before the IF.
-- Seed one ACTIVE Hep investigation (CASE_UID 20000100, condition 10100 ->
-- CONDITION_KEY 35) + its F_PAGE_CASE row so #TMP_F_PAGE_CASE projects exactly 1
-- row. Pre-fix: logged row_count=0. Post-fix: logged row_count=1.
USE RDB_MODERN;
INSERT INTO dbo.INVESTIGATION (INVESTIGATION_KEY, CASE_UID, RECORD_STATUS_CD)
VALUES (99001, 20000100, 'ACTIVE');
INSERT INTO dbo.F_PAGE_CASE (INVESTIGATION_KEY, CONDITION_KEY, PATIENT_KEY)
VALUES (99001, 35, 2);
EXEC dbo.sp_hepatitis_datamart_postprocessing @phc_id = N'20000100', @debug = 0;
