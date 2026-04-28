EXEC rdb_modern..sp_covid_case_datamart_postprocessing 10009289;

SELECT *
FROM rdb_modern..covid_case_datamart
WHERE public_health_case_uid = 10009289
