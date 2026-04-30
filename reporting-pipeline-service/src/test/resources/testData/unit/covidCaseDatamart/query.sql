DECLARE @investigation_uid bigint = 8503;
EXEC RDB_MODERN.dbo.sp_covid_case_datamart_postprocessing @investigation_uid;
SELECT * FROM RDB_MODERN.dbo.COVID_CASE_DATAMART WHERE public_health_case_uid = @investigation_uid;
