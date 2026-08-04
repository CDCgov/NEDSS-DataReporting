/* APP-926 timing + equivalence harness. Re-run after each SP change; compare elapsed, EVENT_METRIC
   logical reads (scan proof), and DATAMART_rows/chk (equivalence: must stay identical). */
USE RDB_MODERN;
SET NOCOUNT ON;

DECLARE @obs NVARCHAR(MAX) = (
    SELECT STRING_AGG(CONVERT(VARCHAR(20), MORB_RPT_UID), ',')
    FROM (SELECT TOP 250 MORB_RPT_UID FROM dbo.MORBIDITY_REPORT WHERE MORB_RPT_KEY <> 1 ORDER BY MORB_RPT_KEY) x
);

-- warm run (prime buffer pool; also lets MERGE targets settle) then reset output
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing @obs, '', '', '', '';
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;

-- timed run
DECLARE @t0 DATETIME2 = SYSDATETIME();
SET STATISTICS IO ON;
EXEC dbo.sp_morbidity_report_datamart_postprocessing @obs, '', '', '', '';
SET STATISTICS IO OFF;
SELECT '@@RESULT SP_elapsed_ms=' + CAST(DATEDIFF(ms, @t0, SYSDATETIME()) AS VARCHAR);
SELECT '@@RESULT DATAMART_rows=' + CAST(COUNT_BIG(*) AS VARCHAR)
     + ' chk=' + CAST(CHECKSUM_AGG(BINARY_CHECKSUM(*)) AS VARCHAR)
FROM dbo.MORBIDITY_REPORT_DATAMART;
