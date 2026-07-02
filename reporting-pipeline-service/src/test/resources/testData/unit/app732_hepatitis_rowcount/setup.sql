-- APP-732: sp_hepatitis_datamart_postprocessing step-3 row_count logging (APP-732).
-- The IF @debug SELECT once sat between SELECT INTO #TMP_F_PAGE_CASE and the
-- SELECT @ROWCOUNT_NO = @@ROWCOUNT capture, so with @debug=0 the predicate-only
-- IF reset @@ROWCOUNT to 0 and JOB_FLOW_LOG recorded row_count=0 even though the
-- temp table had rows. Fix reorders the capture before the IF.
-- Seed one ACTIVE Hep investigation (CASE_UID 20000100, condition 10100) + its
-- F_PAGE_CASE row so #TMP_F_PAGE_CASE projects exactly 1 row.
-- CONDITION_KEY is resolved dynamically so this setup can be re-run across
-- environments where keys differ.
USE RDB_MODERN;
DECLARE @condition_key BIGINT;

SELECT TOP 1 @condition_key = CONDITION_KEY
FROM dbo.CONDITION WITH (NOLOCK)
WHERE CONDITION_CD = '10100'
  AND PROGRAM_AREA_CD = 'HEP'
ORDER BY CONDITION_KEY;

IF @condition_key IS NULL
	THROW 50001, 'APP-732 setup failed: CONDITION 10100/HEP not found in dbo.CONDITION.', 1;

IF NOT EXISTS (
	SELECT 1
	FROM dbo.INVESTIGATION WITH (NOLOCK)
	WHERE INVESTIGATION_KEY = 99001
)
BEGIN
	INSERT INTO dbo.INVESTIGATION (INVESTIGATION_KEY, CASE_UID, RECORD_STATUS_CD)
	VALUES (99001, 20000100, 'ACTIVE');
END;

IF NOT EXISTS (
	SELECT 1
	FROM dbo.F_PAGE_CASE WITH (NOLOCK)
	WHERE INVESTIGATION_KEY = 99001
	  AND CONDITION_KEY = @condition_key
	  AND PATIENT_KEY = 2
)
BEGIN
	INSERT INTO dbo.F_PAGE_CASE (INVESTIGATION_KEY, CONDITION_KEY, PATIENT_KEY)
	VALUES (99001, @condition_key, 2);
END;

EXEC dbo.sp_hepatitis_datamart_postprocessing @phc_id = N'20000100', @debug = 0;
