-- ==========================================
-- ORGANIZATION SERVICE USER CREATION
-- ==========================================
DECLARE @OrgServiceName NVARCHAR(100) = 'organization_service';
DECLARE @OrgUserName NVARCHAR(150) = @OrgServiceName + '_rdb';

-- Grant permissions on ODSE database (READ ONLY)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @CreateUserODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
    EXEC sp_executesql @CreateUserODSESQL;
    PRINT 'Created database user [' + @OrgUserName + '] in NBS_ODSE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @AddRoleMemberODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @OrgUserName + '''';
    EXEC sp_executesql @AddRoleMemberODSESQL;
    PRINT 'Added [' + @OrgUserName + '] to db_datareader role in NBS_ODSE';

    DECLARE @GrantExecSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_organization_event] TO [' + @OrgUserName + ']';
    EXEC sp_executesql @GrantExecSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_organization_event] to [' + @OrgUserName + ']';
END

-- Grant permissions on SRTE database (READ ONLY)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @CreateUserSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
    EXEC sp_executesql @CreateUserSRTESQL;
    PRINT 'Created database user [' + @OrgUserName + '] in NBS_SRTE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @AddRoleMemberSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @OrgUserName + '''';
    EXEC sp_executesql @AddRoleMemberSRTESQL;
    PRINT 'Added [' + @OrgUserName + '] to db_datareader role in NBS_SRTE';
END

-- Grant permissions on RDB_modern database (WRITE)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
    EXEC sp_executesql @CreateUserRDBModernSQL;
    PRINT 'Created database user [' + @OrgUserName + '] in rdb_modern';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @GrantInsertSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @OrgUserName + ']';
    EXEC sp_executesql @GrantInsertSQL;
    PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @OrgUserName + ']';
END

PRINT 'Organization service user creation completed.';