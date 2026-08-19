-- Empty params must produce no datamart rows in this case's key range.
-- A COUNT is used instead of a bare row SELECT because the framework requires the
-- query to return at least one row, so the assertion is that the count equals 0.
-- NOTE keep query.sql comments free of the statement separator character, since the
-- QueryRunner splits the file on that character before it strips comment lines.
SELECT COUNT(*) AS QUALIFYING_ROWS
FROM RDB_MODERN.dbo.MORBIDITY_REPORT_DATAMART
WHERE MORBIDITY_REPORT_KEY BETWEEN 9268000 AND 9268999;
