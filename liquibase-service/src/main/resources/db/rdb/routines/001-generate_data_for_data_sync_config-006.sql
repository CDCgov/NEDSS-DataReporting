-- Removing obsoleted query
DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'EDX_ACTIVITY_LOG';

DELETE
FROM [dbo].[data_sync_config]
WHERE table_name = 'EDX_ACTIVITY_DETAIL_LOG';


INSERT INTO [RDB].[dbo].[data_sync_config]
(table_name, source_db, query, query_with_null_timestamp, query_count, query_with_pagination)
VALUES
    ('EDX_ACTIVITY_LOG', 'NBS_ODSE', 'SELECT *
     FROM EDX_ACTIVITY_LOG
     WHERE record_status_time :operator :timestamp;', NULL, 'SELECT COUNT(*)
     FROM EDX_ACTIVITY_LOG
     WHERE record_status_time :operator :timestamp;', 'WITH PaginatedResults AS (
        SELECT *, ROW_NUMBER() OVER (ORDER BY record_status_time ASC) AS RowNum
        FROM EDX_ACTIVITY_LOG
        WHERE record_status_time :operator :timestamp
    )
    SELECT * FROM PaginatedResults
    WHERE RowNum BETWEEN :startRow AND :endRow;')
;

INSERT INTO [RDB].[dbo].[data_sync_config]
(table_name, source_db, query, query_with_null_timestamp, query_count, query_with_pagination)
VALUES
    ('EDX_ACTIVITY_DETAIL_LOG', 'NBS_ODSE', 'SELECT logg.record_status_time, detail.*
     FROM EDX_ACTIVITY_DETAIL_LOG AS detail
     INNER JOIN EDX_ACTIVITY_LOG AS logg
     ON detail.edx_activity_log_uid = logg.edx_activity_log_uid
     WHERE logg.record_status_time :operator :timestamp;', NULL, 'SELECT COUNT(*)
     FROM EDX_ACTIVITY_DETAIL_LOG AS detail
     INNER JOIN EDX_ACTIVITY_LOG AS logg
     ON detail.edx_activity_log_uid = logg.edx_activity_log_uid
     WHERE logg.record_status_time :operator :timestamp;', 'WITH PaginatedResults AS (
        SELECT logg.record_status_time, detail.*, ROW_NUMBER() OVER (ORDER BY logg.record_status_time ASC) AS RowNum
        FROM EDX_ACTIVITY_DETAIL_LOG AS detail
        INNER JOIN EDX_ACTIVITY_LOG AS logg
        ON detail.edx_activity_log_uid = logg.edx_activity_log_uid
        WHERE logg.record_status_time :operator :timestamp
    )
    SELECT * FROM PaginatedResults
    WHERE RowNum BETWEEN :startRow AND :endRow;')
;