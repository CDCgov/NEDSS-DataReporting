-- ==========================================
-- LDF SERVICE USER CREATION
-- ==========================================
DECLARE @LdfServiceName NVARCHAR(100) = 'ldf_service';
DECLARE @LdfUserName NVARCHAR(150) = @LdfServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
BEGIN
    DECLARE @CreateUserLdfODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
    EXEC sp_executesql @CreateUserLdfODSESQL;
    PRINT 'Created database user [' + @LdfUserName + '] in NBS_ODSE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
BEGIN
    DECLARE @AddRoleMemberLdfODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @LdfUserName + '''';
    EXEC sp_executesql @AddRoleMemberLdfODSESQL;
    PRINT 'Added [' + @LdfUserName + '] to db_datareader role in NBS_ODSE';

    -- Grant EXECUTE permissions on stored procedures
    DECLARE @GrantExecLdfDataSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_data_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfDataSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_data_event] to [' + @LdfUserName + ']';

    DECLARE @GrantExecLdfPatSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_patient_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfPatSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_patient_event] to [' + @LdfUserName + ']';

    DECLARE @GrantExecLdfProvSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_provider_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfProvSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_provider_event] to [' + @LdfUserName + ']';

    DECLARE @GrantExecLdfOrgSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_organization_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfOrgSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_organization_event] to [' + @LdfUserName + ']';

    DECLARE @GrantExecLdfObsSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_observation_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfObsSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_observation_event] to [' + @LdfUserName + ']';

    DECLARE @GrantExecLdfPhcSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_phc_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfPhcSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_phc_event] to [' + @LdfUserName + ']';

    DECLARE @GrantExecLdfIntSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_intervention_event] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantExecLdfIntSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_intervention_event] to [' + @LdfUserName + ']';
END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
BEGIN
    DECLARE @CreateUserLdfSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
    EXEC sp_executesql @CreateUserLdfSRTESQL;
    PRINT 'Created database user [' + @LdfUserName + '] in NBS_SRTE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
BEGIN
    DECLARE @AddRoleMemberLdfSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @LdfUserName + '''';
    EXEC sp_executesql @AddRoleMemberLdfSRTESQL;
    PRINT 'Added [' + @LdfUserName + '] to db_datareader role in NBS_SRTE';
END

-- Grant permissions on RDB_modern database (WRITE to job_flow_log only)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
BEGIN
    DECLARE @CreateUserLdfRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
    EXEC sp_executesql @CreateUserLdfRDBModernSQL;
    PRINT 'Created database user [' + @LdfUserName + '] in rdb_modern';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
BEGIN
    DECLARE @GrantInsertLdfSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @LdfUserName + ']';
    EXEC sp_executesql @GrantInsertLdfSQL;
    PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @LdfUserName + ']';
END

PRINT 'LDF service user creation completed.';