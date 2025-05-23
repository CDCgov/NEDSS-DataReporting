-- SQL Script to create service-specific user for debezium-service
-- This script creates a dedicated user and grants necessary permissions

DECLARE @ServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

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
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in NBS_ODSE';

        -- Grant read permissions on ODSE for existing user
        DECLARE @AddRoleMemberODSEExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberODSEExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_ODSE';

        -- Grant CONNECT permission for existing user
        DECLARE @GrantConnectODSEExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectODSEExistingSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_ODSE';
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

        -- Grant read permissions on SRTE for existing user
        DECLARE @AddRoleMemberSRTEExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberSRTEExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_SRTE';

        -- Grant CONNECT permission for existing user
        DECLARE @GrantConnectSRTEExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectSRTEExistingSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_SRTE';
    END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in all databases and has the correct permissions.';
