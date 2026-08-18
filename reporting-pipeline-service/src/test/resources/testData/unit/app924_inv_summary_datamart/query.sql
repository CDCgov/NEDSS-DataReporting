-- Returns the datamart row only when the SP populated it with the expected values,
-- covering the disease/confirmation fields and the lab-derived specimen date.
-- A wrong or missing value yields zero rows and the harness Await times out (RED).
SELECT
    isd.INVESTIGATION_KEY,
    isd.DISEASE,
    isd.DISEASE_CD,
    isd.CONFIRMATION_METHOD,
    CONVERT(varchar(10), isd.CONFIRMATION_DT, 23)               AS CONFIRMATION_DT,
    CONVERT(varchar(10), isd.EARLIEST_SPECIMEN_COLLECT_DATE, 23) AS EARLIEST_SPECIMEN_COLLECT_DATE,
    isd.LABORATORY_INFORMATION
FROM RDB_MODERN.dbo.INV_SUMM_DATAMART isd
WHERE isd.INVESTIGATION_KEY = 9924001
  AND isd.DISEASE = 'Test Condition'
  AND isd.DISEASE_CD = '10999'
  AND isd.CONFIRMATION_METHOD = 'Lab confirmed'
  AND isd.EARLIEST_SPECIMEN_COLLECT_DATE = '2024-01-10'
  AND isd.LABORATORY_INFORMATION = 'LabInfoXYZ';
