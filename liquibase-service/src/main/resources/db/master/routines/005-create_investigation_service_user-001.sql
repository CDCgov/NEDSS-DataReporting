-- SQL Script to create service-specific user for investigation-service
-- This script creates a dedicated user and grants necessary permissions
-- CORRECTED VERSION with proper table names

DECLARE @ServiceName NVARCHAR(100) = 'investigation_service';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

-- ==========================================
-- Grant permissions on ODSE database (READ + WRITE to specific tables)
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

        -- Grant read permissions for existing user
        DECLARE @AddRoleMemberODSEExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberODSEExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_ODSE';

        -- Grant CONNECT permission for existing user
        DECLARE @GrantConnectODSEExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectODSEExistingSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_ODSE';
    END

-- Grant EXECUTE permission on the stored procedure (always grant regardless of user status)
DECLARE @GrantExecSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_investigation_event] TO [' + @UserName + ']';
EXEC sp_executesql @GrantExecSPSQL;
PRINT 'Granted EXECUTE permission on [dbo].[sp_investigation_event] to [' + @UserName + ']';

-- Grant write permissions on specific tables for investigation service (CORRECTED TABLE NAMES)
DECLARE @GrantWriteSubjectRaceSQL NVARCHAR(MAX) = 'GRANT INSERT, UPDATE, DELETE ON [dbo].[SubjectRaceInfo] TO [' + @UserName + ']';
EXEC sp_executesql @GrantWriteSubjectRaceSQL;
PRINT 'Granted write permissions on [dbo].[SubjectRaceInfo] to [' + @UserName + ']';

DECLARE @GrantWritePHCFactSQL NVARCHAR(MAX) = 'GRANT INSERT, UPDATE, DELETE ON [dbo].[PublicHealthCaseFact] TO [' + @UserName + ']';
EXEC sp_executesql @GrantWritePHCFactSQL;
PRINT 'Granted write permissions on [dbo].[PublicHealthCaseFact] to [' + @UserName + ']';

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

        -- Grant read permissions for existing user
        DECLARE @AddRoleMemberSRTEExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberSRTEExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_SRTE';

        -- Grant CONNECT permission for existing user
        DECLARE @GrantConnectSRTEExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectSRTEExistingSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in NBS_SRTE';
    END

-- ==========================================
-- Grant permissions on RDB_modern database (READ/WRITE)
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

        -- Grant data writer role
        DECLARE @AddRoleMemberRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernWriterSQL;
        PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';

        -- Grant data reader role
        DECLARE @AddRoleMemberRDBModernReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernReaderSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in rdb_modern';
    END
ELSE
    BEGIN
        PRINT 'User [' + @UserName + '] already exists in rdb_modern';

        -- Grant CONNECT permission for existing user
        DECLARE @GrantConnectRDBModernExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
        EXEC sp_executesql @GrantConnectRDBModernExistingSQL;
        PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

        -- Grant data writer role for existing user
        DECLARE @AddRoleMemberRDBModernWriterExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernWriterExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';

        -- Grant data reader role for existing user
        DECLARE @AddRoleMemberRDBModernReaderExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddRoleMemberRDBModernReaderExistingSQL;
        PRINT 'Added [' + @UserName + '] to db_datareader role in rdb_modern';
    END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in all databases and has the correct permissions.';