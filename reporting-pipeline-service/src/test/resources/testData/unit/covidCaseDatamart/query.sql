-- Execute the covid case datamart stored procedure
EXEC rdb_modern..sp_covid_case_datamart_postprocessing 10009289;
-- Return the processed covid case data for 10009289
SELECT * FROM dbo.covid_case_datamart
WHERE public_health_case_uid = 10009289;
