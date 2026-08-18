USE [RDB_MODERN]

DELETE FROM dbo.job_flow_log
WHERE package_Name = 'PublicHealthCaseFact RTR'

EXEC dbo.sp_public_health_case_fact_datamart_event @phc_id_list = '990000076', @debug = 0, @debug_logging = 0
EXEC dbo.sp_public_health_case_fact_datamart_event @phc_id_list = '990000076', @debug = 0, @debug_logging = 1
EXEC dbo.sp_public_health_case_fact_datamart_event @phc_id_list = '990000076', @debug = 1, @debug_logging = 0
EXEC dbo.sp_public_health_case_fact_datamart_event @phc_id_list = '990000076', @debug = 1, @debug_logging = 1
