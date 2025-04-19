-- SQL Script to create service-specific user for investigation-service
-- This script creates a dedicated user to replace the shared NBS_ODS user

DECLARE @ServiceName NVARCHAR(100) = 'investigation_service'; -- Hardcoded service name (lowercase)
DECLARE @UserPassword NVARCHAR(100) = 'DummyPassword123'; -- Will be changed
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb'; -- lowercase _rdb suffix

-- ==========================================
-- Grant permissions on ODSE database (READ)
-- ==========================================
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in ODSE database
        DECLARE @CreateUserODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] WITH PASSWORD = ''' + @UserPassword + '''';
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
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in NBS_ODSE';
    END

-- ==========================================
-- Grant permissions on SRT database (READ)
-- ==========================================
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in SRT database
        DECLARE @CreateUserSRTSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] WITH PASSWORD = ''' + @UserPassword + '''';
        EXEC sp_executesql @CreateUserSRTSQL;
        PRINT 'Created database user [' + @UserName + '] in NBS_SRTE';

        -- Grant read permissions on SRT
        DECLARE @AddRoleMemberSRTSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberSRTSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_SRTE';

        -- Grant CONNECT permission
        DECLARE @GrantConnectSRTSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectSRTSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_SRTE';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in NBS_SRTE';
    END

-- ==========================================
-- Grant permissions on RDB database (READ/WRITE)
-- ==========================================
USE [RDB];
PRINT 'Switched to database [RDB]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in RDB database
        DECLARE @CreateUserRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] WITH PASSWORD = ''' + @UserPassword + '''';
        EXEC sp_executesql @CreateUserRDBSQL;
        PRINT 'Created database user [' + @UserName + '] in RDB';

        DECLARE @AddRoleMemberRDBOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBOwnerSQL;
        PRINT 'Added [' + @UserName + '] to db_owner role in RDB';

        -- Grant CONNECT permission
        DECLARE @GrantConnectRDBSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectRDBSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in RDB';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in RDB';
    END

-- Additionally, access to RDB_MODERN if needed
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Create the user in RDB_MODERN database
        DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] WITH PASSWORD = ''' + @UserPassword + '''';
        EXEC sp_executesql @CreateUserRDBModernSQL;
        PRINT 'Created database user [' + @UserName + '] in rdb_modern';

        DECLARE @AddRoleMemberRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernOwnerSQL;
        PRINT 'Added [' + @UserName + '] to db_owner role in rdb_modern';

        -- Grant CONNECT permission
        DECLARE @GrantConnectRDBModernSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectRDBModernSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in rdb_modern';
    END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in all databases and has the correct permissions.';
