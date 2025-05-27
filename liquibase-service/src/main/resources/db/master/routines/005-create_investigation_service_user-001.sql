-- ==========================================
-- INVESTIGATION SERVICE USER CREATION
-- Special permissions: db_datawriter on ODSE (writes to PublicHealthCaseFact and SubjectRaceInfo)
-- ==========================================
DECLARE @InvServiceName NVARCHAR(100) = 'investigation_service';
DECLARE @InvUserName NVARCHAR(150) = @InvServiceName + '_rdb';

-- Grant permissions on ODSE database (READ + WRITE to specific tables)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
BEGIN
    DECLARE @CreateUserInvODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
    EXEC sp_executesql @CreateUserInvODSESQL;
    PRINT 'Created database user [' + @InvUserName + '] in NBS_ODSE';
END

-- Grant permissions (always execute regardless of user creation)
-- Note: Using db_datawriter because investigation service writes to PublicHealthCaseFact and SubjectRaceInfo tables
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
BEGIN
    DECLARE @AddRoleMemberInvODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @InvUserName + '''';
    EXEC sp_executesql @AddRoleMemberInvODSESQL;
    PRINT 'Added [' + @InvUserName + '] to db_datawriter role in NBS_ODSE';

    -- Grant EXECUTE permissions on stored procedures
    DECLARE @GrantExecInvestigationSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_investigation_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecInvestigationSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_investigation_event] to [' + @InvUserName + ']';

    DECLARE @GrantExecContactSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_contact_record_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecContactSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_contact_record_event] to [' + @InvUserName + ']';

    DECLARE @GrantExecInterviewSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_interview_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecInterviewSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_interview_event] to [' + @InvUserName + ']';

    DECLARE @GrantExecNotificationSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_notification_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecNotificationSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_notification_event] to [' + @InvUserName + ']';

    DECLARE @GrantExecTreatmentSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_treatment_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecTreatmentSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_treatment_event] to [' + @InvUserName + ']';

    DECLARE @GrantExecVaccinationSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_vaccination_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecVaccinationSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_vaccination_event] to [' + @InvUserName + ']';

    DECLARE @GrantExecPHCDatamartSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_public_health_case_fact_datamart_event] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantExecPHCDatamartSQL;
    PRINT 'Granted EXECUTE permission on [dbo].[sp_public_health_case_fact_datamart_event] to [' + @InvUserName + ']';

    -- Grant write permissions on specific tables for investigation service
    DECLARE @GrantWriteSubjectRaceSQL NVARCHAR(MAX) = 'GRANT INSERT, UPDATE, DELETE ON [dbo].[SubjectRaceInfo] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantWriteSubjectRaceSQL;
    PRINT 'Granted write permissions on [dbo].[SubjectRaceInfo] to [' + @InvUserName + ']';

    DECLARE @GrantWritePHCFactSQL NVARCHAR(MAX) = 'GRANT INSERT, UPDATE, DELETE ON [dbo].[PublicHealthCaseFact] TO [' + @InvUserName + ']';
    EXEC sp_executesql @GrantWritePHCFactSQL;
    PRINT 'Granted write permissions on [dbo].[PublicHealthCaseFact] to [' + @InvUserName + ']';
END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
BEGIN
    DECLARE @CreateUserInvSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
    EXEC sp_executesql @CreateUserInvSRTESQL;
    PRINT 'Created database user [' + @InvUserName + '] in NBS_SRTE';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
BEGIN
    DECLARE @AddRoleMemberInvSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @InvUserName + '''';
    EXEC sp_executesql @AddRoleMemberInvSRTESQL;
    PRINT 'Added [' + @InvUserName + '] to db_datareader role in NBS_SRTE';
END

-- Grant permissions on RDB_modern database (READ/WRITE)
-- Note: Requires both db_datareader and db_datawriter because datawriter doesn't include read permissions
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
BEGIN
    DECLARE @CreateUserInvRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
    EXEC sp_executesql @CreateUserInvRDBModernSQL;
    PRINT 'Created database user [' + @InvUserName + '] in rdb_modern';
END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
BEGIN
    -- Grant data writer role
    DECLARE @AddRoleMemberInvRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @InvUserName + '''';
    EXEC sp_executesql @AddRoleMemberInvRDBModernWriterSQL;
    PRINT 'Added [' + @InvUserName + '] to db_datawriter role in rdb_modern';

    -- Grant data reader role (required because db_datawriter doesn't include read permissions)
    DECLARE @AddRoleMemberInvRDBModernReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @InvUserName + '''';
    EXEC sp_executesql @AddRoleMemberInvRDBModernReaderSQL;
    PRINT 'Added [' + @InvUserName + '] to db_datareader role in rdb_modern';
END

PRINT 'Investigation service user creation completed.';