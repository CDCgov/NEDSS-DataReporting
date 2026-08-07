SELECT
    package_Name AS procedure_name,
    Status_Type,
    COUNT(*) AS status_count,
    MIN(row_count) AS minimum_row_count,
    MAX(row_count) AS maximum_row_count
FROM dbo.job_flow_log
WHERE package_Name IN ('PublicHealthCaseFact RTR', 'PCHMartETL')
GROUP BY package_Name, Status_Type
ORDER BY package_Name, Status_Type
