SELECT
    COUNT(*) AS total_count,
    SUM(CASE WHEN Status_Type = 'START' THEN 1 ELSE 0 END) AS start_count,
    SUM(CASE WHEN Status_Type = 'ERROR' THEN 1 ELSE 0 END) AS error_count,
    MAX(CASE WHEN Status_Type = 'START' THEN batch_id END) AS start_batch_id,
    MAX(CASE WHEN Status_Type = 'ERROR' THEN batch_id END) AS error_batch_id,
    MAX(Dataflow_Name) AS dataflow_name,
    MAX(package_Name) AS package_name,
    MAX(CASE WHEN Status_Type = 'START' THEN step_number END) AS start_step_number,
    MAX(CASE WHEN Status_Type = 'ERROR' THEN step_number END) AS error_step_number,
    MAX(CASE WHEN Status_Type = 'START' THEN step_name END) AS start_step_name,
    MAX(CASE WHEN Status_Type = 'ERROR' THEN step_name END) AS error_step_name,
    MAX(CASE WHEN Status_Type = 'START' THEN row_count END) AS start_row_count,
    MAX(CASE WHEN Status_Type = 'ERROR' THEN row_count END) AS error_row_count,
    MAX(CASE WHEN Status_Type = 'START' THEN Msg_Description1 END) AS start_message,
    MAX(CASE WHEN Status_Type = 'ERROR' THEN Msg_Description1 END) AS error_message,
    MAX(CASE WHEN Status_Type = 'ERROR' THEN Error_Description END) AS error_description
FROM dbo.job_flow_log
WHERE package_Name = 'sp_add_job_flow_log_test';
