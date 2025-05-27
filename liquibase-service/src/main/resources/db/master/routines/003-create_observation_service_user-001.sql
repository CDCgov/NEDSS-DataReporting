-- ==========================================
-- OBSERVATION SERVICE USER CREATION
-- ==========================================
DECLARE @ObsServiceName NVARCHAR(100) = 'observation_service';
DECLARE @ObsUserName NVARCHAR(150) = @ObsServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
BEGIN
    DECLARE @CreateUserObsODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
    EXEC sp_executesql @CreateUserObsODSESQL;
    PRINT 'Created database user [' + @ObsUserName + '] in NBS_ODSE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
BEGIN
    DECLARE @AddRoleMemberObsODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @ObsUserName + '''';
    EXEC sp_executesql @AddRoleMemberObsODSESQL;
    PRINT 'Added [' + @ObsUserName + '] to db_datareader role in NBS_ODSE';

    DECLARE @GrantExecObsSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_observation_event] TO [' + @ObsUserName + ']';
    EXEC sp_executesql @GrantExecObsSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_observation_event] to [' + @ObsUserName + ']';

    DECLARE @GrantExecPlaceSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_place_event] TO [' + @ObsUserName + ']';
    EXEC sp_executesql @GrantExecPlaceSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_place_event] to [' + @ObsUserName + ']';
END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
BEGIN
    DECLARE @CreateUserObsSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
    EXEC sp_executesql @CreateUserObsSRTESQL;
    PRINT 'Created database user [' + @ObsUserName + '] in NBS_SRTE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
BEGIN
    DECLARE @AddRoleMemberObsSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @ObsUserName + '''';
    EXEC sp_executesql @AddRoleMemberObsSRTESQL;
    PRINT 'Added [' + @ObsUserName + '] to db_datareader role in NBS_SRTE';
END

-- Grant permissions on RDB_modern database (WRITE to job_flow_log only)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
BEGIN
    DECLARE @CreateUserObsRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
    EXEC sp_executesql @CreateUserObsRDBModernSQL;
    PRINT 'Created database user [' + @ObsUserName + '] in rdb_modern';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
BEGIN
    DECLARE @GrantInsertObsSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @ObsUserName + ']';
    EXEC sp_executesql @GrantInsertObsSQL;
    PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @ObsUserName + ']';
END

PRINT 'Observation service user creation completed.';