-- Removing obsoleted query
DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_RISK_FACTOR';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_ADMINISTRATIVE';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_EPIDEMIOLOGY';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_HIV';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_LAB_FINDING';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_MEDICAL_HISTORY';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_TREATMENT';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'D_INV_VACCINATION';

-- Inserting updated query
INSERT INTO [dbo].[data_sync_config]
(table_name, source_db, query, query_with_null_timestamp, query_count, query_with_pagination)
VALUES
    ('D_INV_RISK_FACTOR', 'RDB', 'SELECT D_INV_RISK_FACTOR.* FROM D_INV_RISK_FACTOR JOIN F_PAGE_CASE ON D_INV_RISK_FACTOR.D_INV_RISK_FACTOR_KEY = F_PAGE_CASE.D_INV_RISK_FACTOR_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_RISK_FACTOR.* FROM D_INV_RISK_FACTOR JOIN F_PAGE_CASE ON D_INV_RISK_FACTOR.D_INV_RISK_FACTOR_KEY = F_PAGE_CASE.D_INV_RISK_FACTOR_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_RISK_FACTOR JOIN F_PAGE_CASE ON D_INV_RISK_FACTOR.D_INV_RISK_FACTOR_KEY = F_PAGE_CASE.D_INV_RISK_FACTOR_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_RISK_FACTOR.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_RISK_FACTOR JOIN F_PAGE_CASE ON D_INV_RISK_FACTOR.D_INV_RISK_FACTOR_KEY = F_PAGE_CASE.D_INV_RISK_FACTOR_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_ADMINISTRATIVE', 'RDB', 'SELECT D_INV_ADMINISTRATIVE.* FROM D_INV_ADMINISTRATIVE JOIN F_PAGE_CASE ON D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY = F_PAGE_CASE.D_INV_ADMINISTRATIVE_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_ADMINISTRATIVE.* FROM D_INV_ADMINISTRATIVE JOIN F_PAGE_CASE ON D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY = F_PAGE_CASE.D_INV_ADMINISTRATIVE_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_ADMINISTRATIVE JOIN F_PAGE_CASE ON D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY = F_PAGE_CASE.D_INV_ADMINISTRATIVE_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_ADMINISTRATIVE.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_ADMINISTRATIVE JOIN F_PAGE_CASE ON D_INV_ADMINISTRATIVE.D_INV_ADMINISTRATIVE_KEY = F_PAGE_CASE.D_INV_ADMINISTRATIVE_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_EPIDEMIOLOGY', 'RDB', 'SELECT D_INV_EPIDEMIOLOGY.* FROM D_INV_EPIDEMIOLOGY JOIN F_PAGE_CASE ON D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY = F_PAGE_CASE.D_INV_EPIDEMIOLOGY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_EPIDEMIOLOGY.* FROM D_INV_EPIDEMIOLOGY JOIN F_PAGE_CASE ON D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY = F_PAGE_CASE.D_INV_EPIDEMIOLOGY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_EPIDEMIOLOGY JOIN F_PAGE_CASE ON D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY = F_PAGE_CASE.D_INV_EPIDEMIOLOGY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_EPIDEMIOLOGY.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_EPIDEMIOLOGY JOIN F_PAGE_CASE ON D_INV_EPIDEMIOLOGY.D_INV_EPIDEMIOLOGY_KEY = F_PAGE_CASE.D_INV_EPIDEMIOLOGY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_HIV', 'RDB', 'SELECT D_INV_HIV.* FROM D_INV_HIV JOIN F_PAGE_CASE ON D_INV_HIV.D_INV_HIV_KEY = F_PAGE_CASE.D_INV_HIV_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_HIV.* FROM D_INV_HIV JOIN F_PAGE_CASE ON D_INV_HIV.D_INV_HIV_KEY = F_PAGE_CASE.D_INV_HIV_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_HIV JOIN F_PAGE_CASE ON D_INV_HIV.D_INV_HIV_KEY = F_PAGE_CASE.D_INV_HIV_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_HIV.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_HIV JOIN F_PAGE_CASE ON D_INV_HIV.D_INV_HIV_KEY = F_PAGE_CASE.D_INV_HIV_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_LAB_FINDING', 'RDB', 'SELECT D_INV_LAB_FINDING.* FROM D_INV_LAB_FINDING JOIN F_PAGE_CASE ON D_INV_LAB_FINDING.D_INV_LAB_FINDING_KEY = F_PAGE_CASE.D_INV_LAB_FINDING_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_LAB_FINDING.* FROM D_INV_LAB_FINDING JOIN F_PAGE_CASE ON D_INV_LAB_FINDING.D_INV_LAB_FINDING_KEY = F_PAGE_CASE.D_INV_LAB_FINDING_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_LAB_FINDING JOIN F_PAGE_CASE ON D_INV_LAB_FINDING.D_INV_LAB_FINDING_KEY = F_PAGE_CASE.D_INV_LAB_FINDING_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_LAB_FINDING.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_LAB_FINDING JOIN F_PAGE_CASE ON D_INV_LAB_FINDING.D_INV_LAB_FINDING_KEY = F_PAGE_CASE.D_INV_LAB_FINDING_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_MEDICAL_HISTORY', 'RDB', 'SELECT D_INV_MEDICAL_HISTORY.* FROM D_INV_MEDICAL_HISTORY JOIN F_PAGE_CASE ON D_INV_MEDICAL_HISTORY.D_INV_MEDICAL_HISTORY_KEY = F_PAGE_CASE.D_INV_MEDICAL_HISTORY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_MEDICAL_HISTORY.* FROM D_INV_MEDICAL_HISTORY JOIN F_PAGE_CASE ON D_INV_MEDICAL_HISTORY.D_INV_MEDICAL_HISTORY_KEY = F_PAGE_CASE.D_INV_MEDICAL_HISTORY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_MEDICAL_HISTORY JOIN F_PAGE_CASE ON D_INV_MEDICAL_HISTORY.D_INV_MEDICAL_HISTORY_KEY = F_PAGE_CASE.D_INV_MEDICAL_HISTORY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_MEDICAL_HISTORY.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_MEDICAL_HISTORY JOIN F_PAGE_CASE ON D_INV_MEDICAL_HISTORY.D_INV_MEDICAL_HISTORY_KEY = F_PAGE_CASE.D_INV_MEDICAL_HISTORY_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_TREATMENT', 'RDB', 'SELECT D_INV_TREATMENT.* FROM D_INV_TREATMENT JOIN F_PAGE_CASE ON D_INV_TREATMENT.D_INV_TREATMENT_KEY = F_PAGE_CASE.D_INV_TREATMENT_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_TREATMENT.* FROM D_INV_TREATMENT JOIN F_PAGE_CASE ON D_INV_TREATMENT.D_INV_TREATMENT_KEY = F_PAGE_CASE.D_INV_TREATMENT_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_TREATMENT JOIN F_PAGE_CASE ON D_INV_TREATMENT.D_INV_TREATMENT_KEY = F_PAGE_CASE.D_INV_TREATMENT_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_TREATMENT.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_TREATMENT JOIN F_PAGE_CASE ON D_INV_TREATMENT.D_INV_TREATMENT_KEY = F_PAGE_CASE.D_INV_TREATMENT_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;'), ('D_INV_VACCINATION', 'RDB', 'SELECT D_INV_VACCINATION.* FROM D_INV_VACCINATION JOIN F_PAGE_CASE ON D_INV_VACCINATION.D_INV_VACCINATION_KEY = F_PAGE_CASE.D_INV_VACCINATION_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'SELECT D_INV_VACCINATION.* FROM D_INV_VACCINATION JOIN F_PAGE_CASE ON D_INV_VACCINATION.D_INV_VACCINATION_KEY = F_PAGE_CASE.D_INV_VACCINATION_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME IS NULL;', 'SELECT COUNT(*) FROM D_INV_VACCINATION JOIN F_PAGE_CASE ON D_INV_VACCINATION.D_INV_VACCINATION_KEY = F_PAGE_CASE.D_INV_VACCINATION_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp;', 'WITH PaginatedResults AS (SELECT D_INV_VACCINATION.*, ROW_NUMBER() OVER (ORDER BY INVESTIGATION.LAST_CHG_TIME ASC) AS RowNum FROM D_INV_VACCINATION JOIN F_PAGE_CASE ON D_INV_VACCINATION.D_INV_VACCINATION_KEY = F_PAGE_CASE.D_INV_VACCINATION_KEY JOIN INVESTIGATION ON F_PAGE_CASE.INVESTIGATION_KEY = INVESTIGATION.INVESTIGATION_KEY WHERE INVESTIGATION.LAST_CHG_TIME :operator :timestamp) SELECT * FROM PaginatedResults WHERE RowNum BETWEEN :startRow AND :endRow;')
;