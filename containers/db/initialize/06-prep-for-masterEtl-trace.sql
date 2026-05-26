------------------------------------------------
-- Drop Tables
------------------------------------------------
USE [RDB]

drop table D_INVESTIGATION_REPEAT;
drop table L_INVESTIGATION_REPEAT;
drop table S_INVESTIGATION_REPEAT;

drop table D_INVESTIGATION_REPEAT_INC;
drop table L_INVESTIGATION_REPEAT_INC;
drop table S_INVESTIGATION_REPEAT_INC;

GO

------------------------------------------------
-- Set file sizes
------------------------------------------------
ALTER DATABASE RDB MODIFY FILE (NAME = 'RDB_log', SIZE = 4096MB);
GO
ALTER DATABASE RDB MODIFY FILE (NAME = 'RDB_log',  MAXSIZE = UNLIMITED, FILEGROWTH = 256MB);
GO

------------------------------------------------
-- Enable CDC
------------------------------------------------

USE [RDB]
EXEC sys.sp_cdc_enable_db;
GO
