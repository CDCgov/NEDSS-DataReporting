-- SQL Script to create service-specific user for kafka-sync-connector-service
-- This script creates a dedicated user and grants necessary permissions

DECLARE @ServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

-- ==========================================
-- Grant permissions on RDB_modern database (WRITE)
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

        -- Grant db_datawriter role
        DECLARE @AddRoleMemberRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernWriterSQL;
        PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in rdb_modern';

        -- Grant CONNECT permission
        DECLARE @GrantConnectRDBModernExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectRDBModernExistingSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

        -- Grant db_datawriter role
        DECLARE @AddRoleMemberRDBModernWriterExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernWriterExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';
    END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in the database and has the correct permissions.';