USE [master];
GO

---------------------------------------------------------------------------------------------------
--  MASTER
---------------------------------------------------------------------------------------------------
RESTORE DATABASE [MASTER] FROM DISK = N'/var/opt/database/initialize/restore.d/MASTER.bak' WITH REPLACE
GO
