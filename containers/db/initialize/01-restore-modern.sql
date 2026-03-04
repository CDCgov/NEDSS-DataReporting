USE [master];

---------------------------------------------------------------------------------------------------
--  RDB_MODERN (Copy of RDB)
---------------------------------------------------------------------------------------------------

IF DB_ID('rdb_modern') IS NULL
BEGIN
	-- Create backup of RDB
    BACKUP DATABASE RDB TO DISK = '/tmp/RDB.bak' WITH COMPRESSION;

    -- Restore backup to rdb_modern
    RESTORE DATABASE [RDB_MODERN] FROM  DISK = N'/tmp/RDB.bak' WITH  FILE = 1,
    MOVE N'RDB' TO N'/var/opt/mssql/data/rdb_modern_data.mdf',
    MOVE N'RDB_log' TO N'/var/opt/mssql/data/rdb_modern_log.ldf',  NOUNLOAD,  STATS = 10


    EXEC dbo.sp_dbcmptlevel @dbname=N'RDB_MODERN', @new_cmptlevel=120
END
