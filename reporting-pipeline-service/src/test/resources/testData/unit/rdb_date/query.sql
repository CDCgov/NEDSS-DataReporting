-- Exact row count for 1990-01-01..2030-12-31 plus null row: expected total = 14976
SELECT COUNT(*) as row_count
FROM RDB_MODERN.dbo.RDB_DATE
;

-- Null/default row exists: DATE_KEY = 1 and DATE_MM_DD_YYYY is null
SELECT *
FROM RDB_MODERN.dbo.RDB_DATE
where DATE_KEY=1 AND DATE_MM_DD_YYYY is NULL;

-- Lower boundary
SELECT TOP(1) DATE_KEY, DATE_MM_DD_YYYY
FROM RDB_MODERN.dbo.RDB_DATE
where DATE_MM_DD_YYYY is not NULL
ORDER BY DATE_MM_DD_YYYY asc;

-- Upper boundary
SELECT TOP(1) DATE_KEY, DATE_MM_DD_YYYY
FROM RDB_MODERN.dbo.RDB_DATE
where DATE_MM_DD_YYYY is not NULL
ORDER BY DATE_MM_DD_YYYY desc;

-- No duplicate keys:
SELECT COUNT(*) as count_rows, COUNT(DISTINCT DATE_KEY) as count_distinct_rows
FROM RDB_MODERN.dbo.RDB_DATE
;