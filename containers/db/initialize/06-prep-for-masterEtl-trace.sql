------------------------------------------------
-- Drop Tables
------------------------------------------------
USE [RDB]

-- IF EXISTS so the script is idempotent and tolerant of RDB images where
-- these tables are absent (the unguarded drops aborted nbs-mssql init on
-- the latest image, exiting the container before liquibase could run).
drop table if exists D_INVESTIGATION_REPEAT;
drop table if exists L_INVESTIGATION_REPEAT;
drop table if exists S_INVESTIGATION_REPEAT;

drop table if exists D_INVESTIGATION_REPEAT_INC;
drop table if exists L_INVESTIGATION_REPEAT_INC;
drop table if exists S_INVESTIGATION_REPEAT_INC;

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
