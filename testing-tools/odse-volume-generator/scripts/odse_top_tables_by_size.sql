/*
  Top tables by on-disk size across the whole NBS_ODSE database.  READ-ONLY.

  The volume-profile script named 22 business tables. On Kentucky those summed to
  ~543 GB of a 3,241 GB database, so ~2.7 TB lives elsewhere (likely HL7/document
  payloads, audit, CDC capture, or metadata). This finds where.

  Run connected to your NBS_ODSE database. Metadata only, no scans, no writes.
  Please send back the result.
*/

SET NOCOUNT ON;

SELECT TOP 30
    CAST(s.name AS varchar(20))                                      AS [schema],
    CAST(t.name AS varchar(60))                                      AS table_name,
    SUM(CASE WHEN ps.index_id IN (0, 1) THEN ps.row_count ELSE 0 END) AS [row_count],
    CAST(SUM(ps.reserved_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(18, 2)) AS reserved_gb
FROM sys.dm_db_partition_stats ps
JOIN sys.tables t  ON t.object_id = ps.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
GROUP BY s.name, t.name
ORDER BY SUM(ps.reserved_page_count) DESC;
