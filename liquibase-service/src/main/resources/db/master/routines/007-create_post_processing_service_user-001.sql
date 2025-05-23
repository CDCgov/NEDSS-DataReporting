-- SQL Script to create service-specific user for post-processing-service
-- This script creates a dedicated user and grants necessary permissions

DECLARE @ServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

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

    -- Grant data reader role
    DECLARE @AddRoleMemberRDBModernReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBModernReaderSQL;
    PRINT 'Added [' + @UserName + '] to db_datareader role in rdb_modern';

    -- Grant data writer role
    DECLARE @AddRoleMemberRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBModernWriterSQL;
    PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';
END
ELSE
BEGIN
    PRINT 'User [' + @UserName + '] already exists in rdb_modern';

    -- Grant CONNECT permission for existing user
    DECLARE @GrantConnectRDBModernExistingSQL NVARCHAR(MAX) = 'GRANT CONNECT TO [' + @UserName + ']';
    EXEC sp_executesql @GrantConnectRDBModernExistingSQL;
    PRINT 'Granted CONNECT permission to [' + @UserName + '] in rdb_modern';

    -- Grant data reader role for existing user
    DECLARE @AddRoleMemberRDBModernReaderExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBModernReaderExistingSQL;
    PRINT 'Added [' + @UserName + '] to db_datareader role in rdb_modern';

    -- Grant data writer role for existing user
    DECLARE @AddRoleMemberRDBModernWriterExistingSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @UserName + '''';
    EXEC sp_executesql @AddRoleMemberRDBModernWriterExistingSQL;
    PRINT 'Added [' + @UserName + '] to db_datawriter role in rdb_modern';
END

-- Grant EXECUTE permission on all post-processing stored procedures (always grant regardless of user status)
DECLARE @GrantExecSQL NVARCHAR(MAX) =
'DECLARE @sql NVARCHAR(MAX) = '''';
SELECT @sql = @sql + ''GRANT EXECUTE ON ['' + SCHEMA_NAME(schema_id) + ''].['' + name + ''] TO [' + @UserName + '];'' + CHAR(13)
FROM sys.procedures
WHERE name LIKE ''sp_%_postprocessing%''
   OR name LIKE ''sp_%_datamart%''
   OR name LIKE ''sp_nrt_%''
   OR name LIKE ''sp_f_%''
   OR name LIKE ''sp_d_%''
 EXEC sp_executesql @sql;';
EXEC sp_executesql @GrantExecSQL;
PRINT 'Granted EXECUTE permission on all post-processing stored procedures to [' + @UserName + ']';

-- ==========================================
-- Verify permissions for the new user
-- ==========================================
PRINT 'User creation completed. Verify that the user has been created in the database and has the correct permissions.';
