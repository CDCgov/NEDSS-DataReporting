-- ==========================================
-- POST PROCESSING SERVICE USER CREATION
-- Special permissions:
-- - db_owner on both RDB and RDB_modern (creates/alters tables, indexes, procedures)
-- - db_datareader on NBS_SRTE (access to information schema for stored procedures)
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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @PostUserName + '] in rdb...';
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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @PostUserName + '] in rdb_modern...';
        DECLARE @AddRoleMemberPostRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostRDBModernOwnerSQL;
        PRINT 'Added [' + @PostUserName + '] to db_owner role in rdb_modern';
    END

-- Grant permissions on NBS_SRTE database (DB_DATAREADER)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @CreateUserPostNBSSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
        EXEC sp_executesql @CreateUserPostNBSSRTESQL;
        PRINT 'Created database user [' + @PostUserName + '] in NBS_SRTE';
    END

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @PostUserName + '] in NBS_SRTE...';
        DECLARE @AddRoleMemberPostNBSSRTEReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostNBSSRTEReaderSQL;
        PRINT 'Added [' + @PostUserName + '] to db_datareader role in NBS_SRTE';
    END

PRINT 'Post-processing service user permissions completed:';
PRINT '- db_owner permissions on rdb and rdb_modern databases';
PRINT '- db_datareader permissions on NBS_SRTE database (for information schema access)';