USE [RDB_MODERN]

DELETE FROM dbo.job_flow_log
WHERE package_Name = 'sp_add_job_flow_log_test';

EXEC dbo.sp_add_job_flow_log
    @batch_id = 990000001,
    @dataflow_name = 'Job Flow Log Test',
    @package_name = 'sp_add_job_flow_log_test',
    @status_type = 'START',
    @step_number = 1,
    @step_name = 'Test start',
    @row_count = 7,
    @msg_description1 = 'Test message';

EXEC dbo.sp_add_job_flow_log
    @batch_id = 990000002,
    @dataflow_name = 'Job Flow Log Test',
    @package_name = 'sp_add_job_flow_log_test',
    @status_type = 'ERROR',
    @step_number = 2,
    @step_name = 'Test error',
    @row_count = 0,
    @msg_description1 = 'Test error message',
    @error_description = 'Test error description';
