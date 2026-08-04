/*  APP-926 equivalence capture.
    For each of 8 scenarios: TRUNCATE datamart, EXEC the currently-deployed SP,
    snapshot the resulting MORBIDITY_REPORT_DATAMART into dbo.$(PFX)_<n>.
    Run once with the ORIGINAL SP deployed (PFX=orig) and once with the
    OPTIMIZED SP deployed (PFX=new).  Non-fatal internal errors are caught by
    the SP's own TRY/CATCH, so the batch keeps going; we log any SP error row.
*/
SET NOCOUNT ON;
:on error ignore

DECLARE @sp NVARCHAR(200) = 'dbo.sp_morbidity_report_datamart_postprocessing';

/* scenario 1: obs-only  (reports 10,11,12) */
IF OBJECT_ID('dbo.$(PFX)_1') IS NOT NULL DROP TABLE dbo.$(PFX)_1;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '10,11,12','','','','', 'false';
SELECT * INTO dbo.$(PFX)_1 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 2: pat-only  (UID 8000001 -> report 2) */
IF OBJECT_ID('dbo.$(PFX)_2') IS NOT NULL DROP TABLE dbo.$(PFX)_2;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '','8000001','','','', 'false';
SELECT * INTO dbo.$(PFX)_2 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 3: prov-only (physician 8000002 -> report 3, reporter 8000003 -> report 4) */
IF OBJECT_ID('dbo.$(PFX)_3') IS NOT NULL DROP TABLE dbo.$(PFX)_3;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '','','8000002,8000003','','', 'false';
SELECT * INTO dbo.$(PFX)_3 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 4: org-only  (src org 8000004 -> report 5, hsptl 8000005 -> report 6) */
IF OBJECT_ID('dbo.$(PFX)_4') IS NOT NULL DROP TABLE dbo.$(PFX)_4;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '','','','8000004,8000005','', 'false';
SELECT * INTO dbo.$(PFX)_4 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 5: inv-only  (CASE_UID 10000013 -> report 7) */
IF OBJECT_ID('dbo.$(PFX)_5') IS NOT NULL DROP TABLE dbo.$(PFX)_5;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '','','','','10000013', 'false';
SELECT * INTO dbo.$(PFX)_5 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 6: mixed  (all five branches) */
IF OBJECT_ID('dbo.$(PFX)_6') IS NOT NULL DROP TABLE dbo.$(PFX)_6;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '10,11,12','8000001','8000002,8000003','8000004,8000005','10000013', 'false';
SELECT * INTO dbo.$(PFX)_6 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 7: empty  (all '') */
IF OBJECT_ID('dbo.$(PFX)_7') IS NOT NULL DROP TABLE dbo.$(PFX)_7;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing '','','','','', 'false';
SELECT * INTO dbo.$(PFX)_7 FROM dbo.MORBIDITY_REPORT_DATAMART;

/* scenario 8: junk in obs  ('abc,,-1,999999999999') */
IF OBJECT_ID('dbo.$(PFX)_8') IS NOT NULL DROP TABLE dbo.$(PFX)_8;
TRUNCATE TABLE dbo.MORBIDITY_REPORT_DATAMART;
EXEC dbo.sp_morbidity_report_datamart_postprocessing 'abc,,-1,999999999999','','','','', 'false';
SELECT * INTO dbo.$(PFX)_8 FROM dbo.MORBIDITY_REPORT_DATAMART;

SELECT '$(PFX) capture done' AS status;
SELECT 1 sc, COUNT(*) rows FROM dbo.$(PFX)_1
UNION ALL SELECT 2, COUNT(*) FROM dbo.$(PFX)_2
UNION ALL SELECT 3, COUNT(*) FROM dbo.$(PFX)_3
UNION ALL SELECT 4, COUNT(*) FROM dbo.$(PFX)_4
UNION ALL SELECT 5, COUNT(*) FROM dbo.$(PFX)_5
UNION ALL SELECT 6, COUNT(*) FROM dbo.$(PFX)_6
UNION ALL SELECT 7, COUNT(*) FROM dbo.$(PFX)_7
UNION ALL SELECT 8, COUNT(*) FROM dbo.$(PFX)_8
ORDER BY sc;
