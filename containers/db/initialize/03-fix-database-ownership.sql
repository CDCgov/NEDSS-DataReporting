-- ==========================================
-- Fix Database Ownership
-- This prevents "Msg 15517: Principal 'dbo' does not exist"
-- which occurs when a database is restored from a backup
-- and the original owner principal is missing.
-- ==========================================

USE [master];
GO

DECLARE @DBName NVARCHAR(128);
DECLARE @OwnerName NVARCHAR(128) = 'sa';

-- On AWS RDS, the master user should be the owner, not 'sa'
-- We identify the master user by selecting the top enabled SQL login
IF EXISTS (SELECT 1 FROM sys.databases WHERE NAME = 'rdsadmin')
BEGIN
    PRINT 'AWS RDS detected. Resolving master user for ownership...';
    SELECT TOP 1 @OwnerName = name 
    FROM sys.server_principals 
    WHERE type_desc = 'SQL_LOGIN' 
      AND is_disabled = 0 
      AND name NOT IN ('rdsadmin', 'rdsa')
    ORDER BY create_date;
END

DECLARE db_cursor CURSOR FOR 
SELECT name FROM sys.databases 
WHERE name IN ('NBS_ODSE', 'NBS_SRTE', 'RDB', 'RDB_MODERN', 'NBS_MSGOUTE');

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Setting owner of database [' + @DBName + '] to [' + @OwnerName + ']';
    BEGIN TRY
        EXEC('ALTER AUTHORIZATION ON DATABASE::[' + @DBName + '] TO [' + @OwnerName + ']');
    END TRY
    BEGIN CATCH
        PRINT 'WARNING: Could not set owner for ' + @DBName + '. Error: ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM db_cursor INTO @DBName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
GO
