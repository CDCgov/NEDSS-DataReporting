SELECT TOP 1
    l.Step_Number,
    l.Step_Name,
    l.Status_Type,
    CASE WHEN l.Error_Description LIKE '%Error Number: 120%' THEN 120 ELSE -1 END AS ERROR_NUMBER,
    CASE WHEN l.Error_Description LIKE '%fewer items than the insert list%' THEN 1 ELSE 0 END AS IS_COLUMN_COUNT_MISMATCH
FROM RDB_MODERN.DBO.JOB_FLOW_LOG l
WHERE l.package_Name = 'sp_covid_case_datamart_postprocessing'
  AND l.Status_Type = 'ERROR'
ORDER BY l.record_id DESC
