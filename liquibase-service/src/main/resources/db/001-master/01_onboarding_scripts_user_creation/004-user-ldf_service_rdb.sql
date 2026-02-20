-- ==========================================
-- USER: ldf_service_rdb
-- SERVICE: ldf-service
-- ==========================================
USE [master];

DECLARE @UserName NVARCHAR(150) = 'ldf_service_rdb';
DECLARE @UserPassword NVARCHAR(128) = N'ldf_service'; --Please provide your generated password.

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        DECLARE @CreateMasterLogin NVARCHAR(MAX) = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateMasterLogin;
        PRINT 'Created login [' + @UserName + ']';
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
         -- Grant data reader role
        DECLARE @AddOdseRoleReader NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddOdseRoleReader;
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
        DECLARE @AddSrteRoleReader NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddSrteRoleReader;
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

-- Create user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @CreateRdbUser NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateRdbUser;
        PRINT 'Created database user [' + @UserName + '] in ' +@RDB_DB;
    END

-- Add permissions
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Grand data writer for job_flow_log
        DECLARE @AddRdbRoleWriterJobFlowLog NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @UserName + ']';
        EXEC sp_executesql @AddRdbRoleWriterJobFlowLog;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @UserName + ']';

        -- Grant execute
        DECLARE @GrantExecute NVARCHAR(MAX) = 'GRANT EXECUTE TO [' + @UserName + ']';
        EXEC sp_executesql @GrantExecute;
        PRINT 'Granted EXECUTE permission to [' + @UserName + ']';
    END

PRINT 'LDF service permission grants completed.';
