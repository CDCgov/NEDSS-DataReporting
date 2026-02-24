-- ==========================================
-- USER: debezium_service_rdb
-- SERVICE: liquibase
-- ==========================================
USE [master];

-- Create login for debezium service
DECLARE @UserName NVARCHAR(150) ='debezium_service_rdb';
DECLARE @UserPassword NVARCHAR(128) = N'debezium_service'; --Please provide your generated password.

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        DECLARE @CreateMasterLogin NVARCHAR(MAX) = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateMasterLogin;
        PRINT 'Created login [' + @UserName + ']';

        -- Grant server-level permissions
        DECLARE @PermissionGrantSQL NVARCHAR(MAX) = 'GRANT VIEW SERVER STATE TO [' + @UserName + ']';
        EXEC sp_executesql @PermissionGrantSQL;
        PRINT 'Granted VIEW SERVER STATE permission to [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- ==========================================
-- NBS_ODSE
-- ==========================================
USE [NBS_ODSE];

-- Create user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @CreateOdseUser NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateOdseUser;
        PRINT 'Created database user [' + @UserName + '] in NBS_ODSE';
    END

-- Add permissions
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @AddOdseRoleDataReader NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddOdseRoleDataReader;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_ODSE';
    END

-- ==========================================
-- NBS_SRTE
-- ==========================================
USE [NBS_SRTE];

-- Create user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @CreateSrteUser NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateSrteUser;
        PRINT 'Created database user [' + @UserName + '] in NBS_SRTE';
    END

-- Add permissions
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @AddSrteRoleDataReader NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddSrteRoleDataReader;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_SRTE';
    END

-- ==========================================
-- RDB / RDB_MODERN
-- ==========================================
-- Switch to configured RTR target database
IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
    BEGIN
        USE rdb_modern;
        PRINT 'Switched to database rdb_modern'
    END
ELSE
    BEGIN
        USE rdb;
        PRINT 'Switched to database rdb';
    END

DECLARE @RDB_DB NVARCHAR(128) = db_name()
--No RDB/RDB_Modern permissions are necessary but Liquibase requires a reset to the initial database for tracking purposes

PRINT 'Debezium service user permission grants completed.';
