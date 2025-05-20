-- SQL Script to create service-specific user for kafka-sync-connector-service
-- This script creates a dedicated user to replace the shared NBS_ODS user

DECLARE @ServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
DECLARE @UserPassword NVARCHAR(100) = 'DummyPassword123';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level with proper parameterization
        DECLARE @CreateLoginSQL NVARCHAR(MAX) = 'CREATE LOGIN [@UserName] WITH PASSWORD=@UserPassword, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL, N'@UserName NVARCHAR(150), @UserPassword NVARCHAR(100)', @UserName, @UserPassword;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- ==========================================
-- Grant permissions on RDB_modern database (WRITE)
-- ==========================================
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in RDB_MODERN database
        DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [@UserName] FOR LOGIN [@UserName]';
        EXEC sp_executesql @CreateUserRDBModernSQL, N'@UserName NVARCHAR(150)', @UserName;
        PRINT 'Created database user [' + @UserName + '] in rdb_modern';

        -- Grant CONNECT permission
        DECLARE @GrantConnectRDBModernSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [@UserName]';
        EXEC sp_executesql @GrantConnectRDBModernSQL, N'@UserName NVARCHAR(150)', @UserName;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

        -- Grant db_datawriter role
        DECLARE @AddRoleMemberRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', @UserName';
        EXEC sp_executesql @AddRoleMemberRDBModernWriterSQL, N'@UserName NVARCHAR(150)', @UserName;
        PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in rdb_modern';
    END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in the database and has the correct permissions.';