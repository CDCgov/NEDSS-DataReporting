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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @LdfUserName + '] in NBS_ODSE...';

        DECLARE @AddRoleMemberLdfODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @LdfUserName + '''';
        EXEC sp_executesql @AddRoleMemberLdfODSESQL;
        PRINT 'Added [' + @LdfUserName + '] to db_datareader role in NBS_ODSE';

        -- Grant EXECUTE permissions on stored procedures with error handling
        BEGIN TRY
            DECLARE @GrantExecLdfDataSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_data_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfDataSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_data_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_data_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecLdfPatSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_patient_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfPatSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_patient_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_patient_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecLdfProvSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_provider_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfProvSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_provider_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_provider_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecLdfOrgSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_organization_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfOrgSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_organization_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_organization_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecLdfObsSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_observation_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfObsSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_observation_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_observation_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecLdfPhcSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_phc_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfPhcSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_phc_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_phc_event] - procedure may not exist yet';
        END CATCH

        BEGIN TRY
            DECLARE @GrantExecLdfIntSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_ldf_intervention_event] TO [' + @LdfUserName + ']';
            EXEC sp_executesql @GrantExecLdfIntSQL;
            PRINT 'Granted EXECUTE permission on [dbo].[sp_ldf_intervention_event] to [' + @LdfUserName + ']';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not grant EXECUTE permission on [dbo].[sp_ldf_intervention_event] - procedure may not exist yet';
        END CATCH
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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @LdfUserName + '] in NBS_SRTE...';
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

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @LdfUserName + '] in rdb_modern...';
        DECLARE @GrantInsertLdfSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @LdfUserName + ']';
        EXEC sp_executesql @GrantInsertLdfSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @LdfUserName + ']';
    END

PRINT 'LDF service user permissions completed.';