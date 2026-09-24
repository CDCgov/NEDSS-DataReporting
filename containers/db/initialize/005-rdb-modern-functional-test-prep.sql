------------------------------------------------
-- Set file sizes
------------------------------------------------
DECLARE @CurrentSize int;

SELECT @CurrentSize = size
FROM
    sys.master_files
WHERE
    name = 'RDB_log'
    AND database_id = (
        SELECT database_id FROM sys.databases
        WHERE name = 'RDB'
    );

IF @CurrentSize < 524288
    BEGIN
        ALTER DATABASE rdb MODIFY FILE (NAME = 'RDB_log', SIZE = 4096MB);
        ALTER DATABASE rdb MODIFY FILE (
            NAME = 'RDB_log', MAXSIZE = UNLIMITED, FILEGROWTH = 256MB
        );
    END
GO

------------------------------------------------
-- Enable CDC
------------------------------------------------

USE rdb
EXEC sys.sp_cdc_enable_db;
GO
