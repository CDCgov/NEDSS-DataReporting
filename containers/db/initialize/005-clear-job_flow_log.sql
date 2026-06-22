-- ==========================================
-- Clear job_flow_logs
-- ==========================================

USE RDB_MODERN;
GO

TRUNCATE TABLE [dbo].[job_flow_log];
