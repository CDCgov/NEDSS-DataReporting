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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @ObsUserName + '] in NBS_ODSE...';

        DECLARE @AddRoleMemberObsODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @ObsUserName + '''';
        EXEC sp_executesql @AddRoleMemberObsODSESQL;
        PRINT 'Added [' + @ObsUserName + '] to db_datareader role in NBS_ODSE';

        -- Grant EXECUTE permissions with error handling
        BEGIN TRY
            DECLARE @GrantExecObsSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_observation_event] TO [' + @ObsUserName + ']';
            EXEC sp_executesql @GrantExecObsSPSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_observation_event] to [' + @ObsUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_observation_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecPlaceSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_place_event] TO [' + @ObsUserName + ']';
            EXEC sp_executesql @GrantExecPlaceSPSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_place_event] to [' + @ObsUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_place_event] - procedure may not exist yet';
        END CATCH
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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @ObsUserName + '] in NBS_SRTE...';
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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @ObsUserName + '] in rdb_modern...';
        DECLARE @GrantInsertObsSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @ObsUserName + ']';
        EXEC sp_executesql @GrantInsertObsSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @ObsUserName + ']';
    END

PRINT 'Observation service user permissions completed.';