-- SQL Script to create service-specific user for observation-service
-- This script creates a dedicated user to replace the shared NBS_ODS user

DECLARE @ServiceName NVARCHAR(100) = 'observation_service';
DECLARE @UserPassword NVARCHAR(100) = 'DummyPassword123';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        DECLARE @CreateLoginSQL NVARCHAR(MAX) = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- ==========================================
-- Grant permissions on ODSE database (READ)
-- ==========================================
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in ODSE database
        DECLARE @CreateUserODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateUserODSESQL;
        PRINT 'Created database user [' + @UserName + '] in NBS_ODSE';

        -- Grant read permissions on ODSE
        DECLARE @AddRoleMemberODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberODSESQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_ODSE';

        -- Grant CONNECT permission
        DECLARE @GrantConnectODSESQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectODSESQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_ODSE';

        -- Grant EXECUTE permission on the store procedure
        DECLARE @GrantExecSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_observation_event] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantExecSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_observation_event] to [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in NBS_ODSE';
    END

-- ==========================================
-- Grant permissions on SRTE database (READ)
-- ==========================================
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in SRTE database
        DECLARE @CreateUserSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateUserSRTESQL;
        PRINT 'Created database user [' + @UserName + '] in NBS_SRTE';

        -- Grant read permissions on SRTE
        DECLARE @AddRoleMemberSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberSRTESQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_SRTE';

        -- Grant CONNECT permission
        DECLARE @GrantConnectSRTESQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectSRTESQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_SRTE';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in NBS_SRTE';
    END

-- ==========================================
-- Grant permissions on RDB_modern database (WRITE to job_flow_log only)
-- ==========================================
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in RDB_MODERN database
        DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateUserRDBModernSQL;
        PRINT 'Created database user [' + @UserName + '] in rdb_modern';

        -- Grant CONNECT permission
        DECLARE @GrantConnectRDBModernSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectRDBModernSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

        -- Grant INSERT permission on job_flow_log table
        DECLARE @GrantInsertSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantInsertSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in rdb_modern';
    END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in all databases and has the correct permissions.';
