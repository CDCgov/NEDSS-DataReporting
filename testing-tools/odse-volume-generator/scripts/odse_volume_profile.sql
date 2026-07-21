/*
  NBS_ODSE volume profile.  READ-ONLY.  No writes, no schema changes.

  Run this connected to your NBS_ODSE database (SSMS, or:
    sqlcmd -S <server> -d NBS_ODSE -i odse_volume_profile.sql -o results.txt).

  Row counts and sizes come from catalog metadata, so the big tables are not
  scanned. The one scan is the unique-patient count over dbo.person.

  Please send back all four result sets.
*/

SET NOCOUNT ON;

/* 1. Row count + on-disk size for the tables that drive reporting volume. */
SELECT
    CAST(t.name AS varchar(40))                              AS table_name,
    SUM(CASE WHEN ps.index_id IN (0, 1) THEN ps.row_count ELSE 0 END)      AS [row_count],
    CAST(SUM(ps.reserved_page_count) * 8.0 / 1024 AS DECIMAL(18, 1)) AS reserved_mb
FROM sys.dm_db_partition_stats ps
JOIN sys.tables t
    ON t.object_id = ps.object_id
   AND t.schema_id = SCHEMA_ID('dbo')
WHERE t.name IN (
    'person', 'person_name', 'entity', 'entity_id',
    'observation', 'obs_value_coded', 'obs_value_txt', 'obs_value_numeric', 'obs_value_date',
    'act', 'act_relationship', 'participation',
    'public_health_case', 'case_management',
    'notification', 'treatment', 'intervention', 'interview', 'place',
    'organization', 'organization_name', 'nbs_case_answer'
)
GROUP BY t.name
ORDER BY [row_count] DESC;

/* 2. Unique patients (MPR). NBS mints a new Person per ingestion; the MPR
   (person_parent_uid) dedups them to a real human, so distinct MPR is the true
   patient count, and dbo.person row count over-reports it. */
SELECT
    COUNT(*)                                                 AS person_rows_pat,
    COUNT(DISTINCT COALESCE(person_parent_uid, person_uid))  AS unique_mpr_patients
FROM dbo.person
WHERE cd = 'PAT';

/* 3. Headline per-patient fan-out (row count / unique patients). This is the
   ratio we need to size synthetic data realistically. */
DECLARE @mpr DECIMAL(18, 2) =
    (SELECT COUNT(DISTINCT COALESCE(person_parent_uid, person_uid))
     FROM dbo.person WHERE cd = 'PAT');

DECLARE @rows TABLE (name SYSNAME, n BIGINT);
INSERT INTO @rows (name, n)
SELECT t.name, SUM(CASE WHEN ps.index_id IN (0, 1) THEN ps.row_count ELSE 0 END)
FROM sys.dm_db_partition_stats ps
JOIN sys.tables t ON t.object_id = ps.object_id AND t.schema_id = SCHEMA_ID('dbo')
WHERE t.name IN ('observation', 'public_health_case', 'act_relationship',
                 'participation', 'obs_value_coded')
GROUP BY t.name;

SELECT
    @mpr AS unique_mpr_patients,
    CAST((SELECT n FROM @rows WHERE name = 'observation')        / NULLIF(@mpr, 0) AS DECIMAL(10, 2)) AS observations_per_patient,
    CAST((SELECT n FROM @rows WHERE name = 'public_health_case') / NULLIF(@mpr, 0) AS DECIMAL(10, 2)) AS investigations_per_patient,
    CAST((SELECT n FROM @rows WHERE name = 'act_relationship')   / NULLIF(@mpr, 0) AS DECIMAL(10, 2)) AS act_relationships_per_patient,
    CAST((SELECT n FROM @rows WHERE name = 'participation')      / NULLIF(@mpr, 0) AS DECIMAL(10, 2)) AS participations_per_patient,
    CAST((SELECT n FROM @rows WHERE name = 'obs_value_coded')    / NULLIF(@mpr, 0) AS DECIMAL(10, 2)) AS obs_values_coded_per_patient;

/* 4. Total database size, for footprint context. */
SELECT CAST(SUM(reserved_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS total_reserved_gb
FROM sys.dm_db_partition_stats;
