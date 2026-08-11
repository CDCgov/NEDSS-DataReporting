SELECT
    package_Name AS procedure_name,
    SUM(CASE WHEN Status_Type = 'START' THEN 1 ELSE 0 END) AS start_count,
    SUM(CASE WHEN Status_Type IN ('COMPLETE', 'COMPLETED') THEN 1 ELSE 0 END) AS complete_count,
    SUM(CASE WHEN Status_Type = 'ERROR' THEN 1 ELSE 0 END) AS error_count,
    COUNT(*) AS total_count
FROM dbo.job_flow_log
WHERE package_Name IN (
    'sp_interview_event',
    'nrt_interview',
    'sp_contact_record_event',
    'sp_treatment_event',
    'sp_vaccination_event',
    'sp_vaccination_record_event'
)
GROUP BY package_Name
ORDER BY package_Name
