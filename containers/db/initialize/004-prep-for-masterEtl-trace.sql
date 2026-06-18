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
DECLARE @CurrentSize int;

SELECT
	@CurrentSize = size
FROM
	sys.master_files
WHERE
	name = 'RDB_log'
	AND database_id = (select database_id from sys.databases where name = 'RDB');

IF @CurrentSize < 524288
BEGIN
  ALTER DATABASE RDB MODIFY FILE (NAME = 'RDB_log', SIZE = 4096MB);
  ALTER DATABASE RDB MODIFY FILE (NAME = 'RDB_log',  MAXSIZE = UNLIMITED, FILEGROWTH = 256MB);
END
GO

------------------------------------------------
-- Enable CDC
------------------------------------------------

USE [RDB]
EXEC sys.sp_cdc_enable_db;
GO
