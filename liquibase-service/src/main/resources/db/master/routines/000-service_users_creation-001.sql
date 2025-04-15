-- SQL Script to create service-specific users with appropriate permissions
-- This script creates users for a specific service to replace the shared NBS_ODS user

-- Variables - Service name should be hardcoded for each service (e.g., 'OrganizationService', 'ProviderService', etc.)
DECLARE @ServiceName NVARCHAR(100) = 'ServiceNameHere'; -- Replace with actual service name
DECLARE @UserPassword NVARCHAR(100) = 'DummyPassword123'; -- Replace with secure password or use placeholder

-- Construct the user name (ServiceName_RDB format)
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_RDB';

-- Create the login at server level
DECLARE @CreateLoginSQL NVARCHAR(MAX) = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[RDB], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
EXEC sp_executesql @CreateLoginSQL;
PRINT 'Created login [' + @UserName + ']';

-- ==========================================
-- Grant permissions on ODSE database (READ)
-- ==========================================
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

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

-- ==========================================
-- Grant permissions on SRT database (READ)
-- ==========================================
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Create the user in SRT database
DECLARE @CreateUserSRTSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
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

-- ==========================================
-- Grant permissions on RDB database (READ/WRITE)
-- ==========================================
USE [RDB];
PRINT 'Switched to database [RDB]';

-- Create the user in RDB database
DECLARE @CreateUserRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
EXEC sp_executesql @CreateUserRDBSQL;
PRINT 'Created database user [' + @UserName + '] in RDB';

-- Grant read/write permissions on RDB
DECLARE @AddRoleMemberRDBReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
EXEC sp_executesql @AddRoleMemberRDBReaderSQL;
DECLARE @AddRoleMemberRDBWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
EXEC sp_executesql @AddRoleMemberRDBWriterSQL;
PRINT 'Added [' + @UserName + '] to db_datareader and db_datawriter roles in RDB';

-- Grant CONNECT permission
DECLARE @GrantConnectRDBSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
EXEC sp_executesql @GrantConnectRDBSQL;
PRINT 'Granted CONNECT permission to [' + @UserName + '] in RDB';

-- Additionally, access to RDB_MODERN if needed
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Create the user in RDB_MODERN database
DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
EXEC sp_executesql @CreateUserRDBModernSQL;
PRINT 'Created database user [' + @UserName + '] in rdb_modern';

-- Grant read/write permissions on RDB_MODERN
DECLARE @AddRoleMemberRDBModernReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
EXEC sp_executesql @AddRoleMemberRDBModernReaderSQL;
DECLARE @AddRoleMemberRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
EXEC sp_executesql @AddRoleMemberRDBModernWriterSQL;
PRINT 'Added [' + @UserName + '] to db_datareader and db_datawriter roles in rdb_modern';

-- Grant CONNECT permission
DECLARE @GrantConnectRDBModernSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
EXEC sp_executesql @GrantConnectRDBModernSQL;
PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in all databases and has the correct permissions.';
