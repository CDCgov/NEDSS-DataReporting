-- SQL Script to create service-specific user for post-processing-service
-- This script creates a dedicated user and grants db_owner permissions on both databases

DECLARE @ServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

-- ==========================================
-- Grant permissions on RDB database (DB_OWNER)
-- ==========================================
USE [rdb];
PRINT 'Switched to database [rdb]';

-- Check if user exists in this database
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
BEGIN
    -- Create the user in RDB database
    DECLARE @CreateUserRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
    EXEC sp_executesql @CreateUserRDBSQL;
    PRINT 'Created database user [' + @UserName + '] in rdb';

    -- Grant CONNECT permission
    DECLARE @GrantConnectRDBSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
    EXEC sp_executesql @GrantConnectRDBSQL;
    PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb';

    -- Grant db_owner role
    DECLARE @AddRoleMemberRDBOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBOwnerSQL;
    PRINT 'Added [' + @UserName + '] to db_owner role in rdb';
END
ELSE
BEGIN
    PRINT 'User [' + @UserName + '] already exists in rdb';

    -- Grant CONNECT permission for existing user
    DECLARE @GrantConnectRDBExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
    EXEC sp_executesql @GrantConnectRDBExistingSQL;
    PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb';

    -- Grant db_owner role for existing user
    DECLARE @AddRoleMemberRDBOwnerExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBOwnerExistingSQL;
    PRINT 'Added [' + @UserName + '] to db_owner role in rdb';
END

-- ==========================================
-- Grant permissions on RDB_modern database (DB_OWNER)
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

    -- Grant db_owner role
    DECLARE @AddRoleMemberRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBModernOwnerSQL;
    PRINT 'Added [' + @UserName + '] to db_owner role in rdb_modern';
END
ELSE
BEGIN
    PRINT 'User [' + @UserName + '] already exists in rdb_modern';

    -- Grant CONNECT permission for existing user
    DECLARE @GrantConnectRDBModernExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
    EXEC sp_executesql @GrantConnectRDBModernExistingSQL;
    PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

    -- Grant db_owner role for existing user
    DECLARE @AddRoleMemberRDBModernOwnerExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBModernOwnerExistingSQL;
    PRINT 'Added [' + @UserName + '] to db_owner role in rdb_modern';
END

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed with db_owner permissions on both rdb and rdb_modern databases.';
PRINT 'The post-processing service user now has full permissions to create/alter tables, columns, indexes, functions, and views.';
PRINT 'Verify that the user has been created in both databases and has the correct permissions.';