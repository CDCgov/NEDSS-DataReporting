-- ==========================================
-- PERSON SERVICE USER CREATION
-- ==========================================
DECLARE @PersonServiceName NVARCHAR(100) = 'person_service';
DECLARE @PersonUserName NVARCHAR(150) = @PersonServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
BEGIN
    DECLARE @CreateUserPersonODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
    EXEC sp_executesql @CreateUserPersonODSESQL;
    PRINT 'Created database user [' + @PersonUserName + '] in NBS_ODSE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
BEGIN
    DECLARE @AddRoleMemberPersonODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PersonUserName + '''';
    EXEC sp_executesql @AddRoleMemberPersonODSESQL;
    PRINT 'Added [' + @PersonUserName + '] to db_datareader role in NBS_ODSE';

    DECLARE @GrantExecPatientSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_patient_event] TO [' + @PersonUserName + ']';
    EXEC sp_executesql @GrantExecPatientSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_patient_event] to [' + @PersonUserName + ']';

    DECLARE @GrantExecRaceSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_patient_race_event] TO [' + @PersonUserName + ']';
    EXEC sp_executesql @GrantExecRaceSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_patient_race_event] to [' + @PersonUserName + ']';

    DECLARE @GrantExecProviderSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_provider_event] TO [' + @PersonUserName + ']';
    EXEC sp_executesql @GrantExecProviderSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_provider_event] to [' + @PersonUserName + ']';

    DECLARE @GrantExecAuthUserSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_auth_user_event] TO [' + @PersonUserName + ']';
    EXEC sp_executesql @GrantExecAuthUserSPSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_auth_user_event] to [' + @PersonUserName + ']';
END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
BEGIN
    DECLARE @CreateUserPersonSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
    EXEC sp_executesql @CreateUserPersonSRTESQL;
    PRINT 'Created database user [' + @PersonUserName + '] in NBS_SRTE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
BEGIN
    DECLARE @AddRoleMemberPersonSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PersonUserName + '''';
    EXEC sp_executesql @AddRoleMemberPersonSRTESQL;
    PRINT 'Added [' + @PersonUserName + '] to db_datareader role in NBS_SRTE';
END

-- Grant permissions on RDB_modern database (WRITE to job_flow_log only)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
BEGIN
    DECLARE @CreateUserPersonRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
    EXEC sp_executesql @CreateUserPersonRDBModernSQL;
    PRINT 'Created database user [' + @PersonUserName + '] in rdb_modern';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
BEGIN
    DECLARE @GrantInsertPersonSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @PersonUserName + ']';
    EXEC sp_executesql @GrantInsertPersonSQL;
    PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @PersonUserName + ']';
END

PRINT 'Person service user creation completed.';