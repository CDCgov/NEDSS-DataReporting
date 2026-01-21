use [master];
go

---------------------------------------------------------------------------------------------------
--  RDB_MODERN (Copy of RDB)
---------------------------------------------------------------------------------------------------

RESTORE DATABASE [RDB_MODERN] FROM  DISK = N'/var/opt/database/initialize/restore.d/RDB.bak' WITH  FILE = 1,
MOVE N'RDB' TO N'/var/opt/mssql/data/rdb_modern_data.mdf',
MOVE N'RDB_log' TO N'/var/opt/mssql/data/rdb_modern_log.ldf',  NOUNLOAD,  STATS = 10
GO

EXEC dbo.sp_dbcmptlevel @dbname=N'RDB_MODERN', @new_cmptlevel=120
GO
