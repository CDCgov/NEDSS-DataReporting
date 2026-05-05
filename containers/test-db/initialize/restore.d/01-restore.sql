USE [master];
GO

---------------------------------------------------------------------------------------------------
--  NBS_ODSE
---------------------------------------------------------------------------------------------------
RESTORE DATABASE [NBS_ODSE] FROM DISK = N'/var/opt/database/initialize/restore.d/NBS_ODSE.bak' WITH RECOVERY, STATS = 10
GO

---------------------------------------------------------------------------------------------------
--  NBS_SRTE
---------------------------------------------------------------------------------------------------
RESTORE DATABASE [NBS_SRTE] FROM DISK = N'/var/opt/database/initialize/restore.d/NBS_SRTE.bak' WITH RECOVERY, KEEP_CDC, STATS = 10
GO

---------------------------------------------------------------------------------------------------
--  NBS_MSGOUTE
---------------------------------------------------------------------------------------------------
RESTORE DATABASE [NBS_MSGOUTE] FROM DISK = N'/var/opt/database/initialize/restore.d/NBS_MSGOUTE.bak' WITH RECOVERY, KEEP_CDC, STATS = 10
GO

---------------------------------------------------------------------------------------------------
--  RDB
---------------------------------------------------------------------------------------------------
RESTORE DATABASE [RDB] FROM DISK = N'/var/opt/database/initialize/restore.d/RDB.bak' WITH RECOVERY, KEEP_CDC, STATS = 10
GO

---------------------------------------------------------------------------------------------------
--  RDB_MODERN
---------------------------------------------------------------------------------------------------
RESTORE DATABASE [RDB_MODERN] FROM DISK = N'/var/opt/database/initialize/restore.d/RDB_MODERN.bak' WITH RECOVERY, KEEP_CDC, STATS = 10
GO


---------------------------------------------------------------------------------------------------
--  ENABLE CDC Capture Jobs (Not automatically started)
---------------------------------------------------------------------------------------------------
USE [NBS_ODSE]
GO
EXEC sys.sp_cdc_add_job 'capture';
EXEC sys.sp_cdc_add_job 'cleanup';
GO

USE [NBS_SRTE]
GO
EXEC sys.sp_cdc_add_job 'capture';
EXEC sys.sp_cdc_add_job 'cleanup';
GO
