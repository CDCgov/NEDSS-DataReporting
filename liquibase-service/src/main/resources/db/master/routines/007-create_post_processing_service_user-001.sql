-- ==========================================
-- POST PROCESSING SERVICE USER CREATION
-- Special permissions: db_owner on both RDB and RDB_modern (creates/alters tables, indexes, procedures)
-- ==========================================
DECLARE @PostServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @PostUserName NVARCHAR(150) = @PostServiceName + '_rdb';

-- Grant permissions on RDB database (DB_OWNER)
USE [rdb];
PRINT 'Switched to database [rdb]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
BEGIN
    DECLARE @CreateUserPostRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
    EXEC sp_executesql @CreateUserPostRDBSQL;
    PRINT 'Created database user [' + @PostUserName + '] in rdb';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
BEGIN
    DECLARE @AddRoleMemberPostRDBOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
    EXEC sp_executesql @AddRoleMemberPostRDBOwnerSQL;
    PRINT 'Added [' + @PostUserName + '] to db_owner role in rdb';
END

-- Grant permissions on RDB_modern database (DB_OWNER)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
BEGIN
    DECLARE @CreateUserPostRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
    EXEC sp_executesql @CreateUserPostRDBModernSQL;
    PRINT 'Created database user [' + @PostUserName + '] in rdb_modern';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
BEGIN
    DECLARE @AddRoleMemberPostRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
    EXEC sp_executesql @AddRoleMemberPostRDBModernOwnerSQL;
    PRINT 'Added [' + @PostUserName + '] to db_owner role in rdb_modern';
END

PRINT 'Post-processing service user creation completed with db_owner permissions on both rdb and rdb_modern databases.';