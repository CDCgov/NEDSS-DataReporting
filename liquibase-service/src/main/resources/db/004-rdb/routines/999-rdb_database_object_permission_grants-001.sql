-- POST PROCESSING SERVICE PERMISSIONS
DECLARE @PostServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @PostUserName NVARCHAR(150) = @PostServiceName + '_rdb';

DECLARE @RDB_DB NVARCHAR(64) = db_name()

-- ==========================================
-- PERMISSION GRANTS
-- ==========================================

-- POST PROCESSING SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostRDBSQL;
--         PRINT 'Created database user [' + @PostUserName + '] in ' +@RDB_DB;
--     END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostRDBOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostRDBOwnerSQL;
        PRINT 'Added [' + @PostUserName + '] to db_owner role in ' +@RDB_DB;
    END

PRINT 'Post-processing service permission grants completed:';
