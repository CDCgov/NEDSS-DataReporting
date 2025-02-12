IF
EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME = 'data_sync_config'
)
BEGIN
IF
EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'data_sync_config' AND COLUMN_NAME = 'last_executed_timestamp')
ALTER TABLE data_sync_config DROP COLUMN last_executed_timestamp;

IF
EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'data_sync_config' AND COLUMN_NAME = 'last_executed_run_time')
ALTER TABLE data_sync_config DROP COLUMN last_executed_run_time;

IF
EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'data_sync_config' AND COLUMN_NAME = 'last_executed_result_count')
ALTER TABLE data_sync_config DROP COLUMN last_executed_result_count;

IF
EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'data_sync_config' AND COLUMN_NAME = 'log_start_row')
ALTER TABLE data_sync_config DROP COLUMN log_start_row;

IF
EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'data_sync_config' AND COLUMN_NAME = 'log_end_row')
ALTER TABLE data_sync_config DROP COLUMN log_end_row;
END;
