-- ==========================================
-- DEBEZIUM SERVICE USER CREATION
-- ==========================================
DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
-- BEGIN
--     DECLARE @CreateUserDebeziumODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
--     EXEC sp_executesql @CreateUserDebeziumODSESQL;
--     PRINT 'Created database user [' + @DebeziumUserName + '] in NBS_ODSE';
-- END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @AddRoleMemberDebeziumODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumODSESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in NBS_ODSE';
    END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
-- BEGIN
--     DECLARE @CreateUserDebeziumSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
--     EXEC sp_executesql @CreateUserDebeziumSRTESQL;
--     PRINT 'Created database user [' + @DebeziumUserName + '] in NBS_SRTE';
-- END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @AddRoleMemberDebeziumSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumSRTESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in NBS_SRTE';
    END

PRINT 'Debezium service user creation completed.';

-- ==========================================
-- KAFKA SYNC CONNECTOR SERVICE USER CREATION
-- ==========================================
DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

-- Grant permissions on RDB_modern database (WRITE)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- -- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @KafkaUserName)
-- BEGIN
--     DECLARE @CreateUserKafkaRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @KafkaUserName + '] FOR LOGIN [' + @KafkaUserName + ']';
--     EXEC sp_executesql @CreateUserKafkaRDBModernSQL;
--     PRINT 'Created database user [' + @KafkaUserName + '] in rdb_modern';
-- END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @KafkaUserName)
    BEGIN
        DECLARE @AddRoleMemberKafkaRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @KafkaUserName + '''';
        EXEC sp_executesql @AddRoleMemberKafkaRDBModernWriterSQL;
        PRINT 'Added [' + @KafkaUserName + '] to db_datawriter role in rdb_modern';
    END

PRINT 'Kafka sync connector service user creation completed.';

-- ==========================================
-- ORGANIZATION SERVICE USER CREATION
-- ==========================================
DECLARE @OrgServiceName NVARCHAR(100) = 'organization_service';
DECLARE @OrgUserName NVARCHAR(150) = @OrgServiceName + '_rdb';

-- Grant permissions on ODSE database (READ ONLY)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
-- BEGIN
--     DECLARE @CreateUserODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
--     EXEC sp_executesql @CreateUserODSESQL;
--     PRINT 'Created database user [' + @OrgUserName + '] in NBS_ODSE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
-- BEGIN
--     DECLARE @CreateUserSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
--     EXEC sp_executesql @CreateUserSRTESQL;
--     PRINT 'Created database user [' + @OrgUserName + '] in NBS_SRTE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
-- BEGIN
--     DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
--     EXEC sp_executesql @CreateUserRDBModernSQL;
--     PRINT 'Created database user [' + @OrgUserName + '] in rdb_modern';
-- END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
BEGIN
    DECLARE @GrantInsertSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @OrgUserName + ']';
    EXEC sp_executesql @GrantInsertSQL;
    PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @OrgUserName + ']';
END

PRINT 'Organization service user creation completed.';

-- ==========================================
-- PERSON SERVICE USER CREATION
-- ==========================================
DECLARE @PersonServiceName NVARCHAR(100) = 'person_service';
DECLARE @PersonUserName NVARCHAR(150) = @PersonServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
-- BEGIN
--     DECLARE @CreateUserPersonODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
--     EXEC sp_executesql @CreateUserPersonODSESQL;
--     PRINT 'Created database user [' + @PersonUserName + '] in NBS_ODSE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
-- BEGIN
--     DECLARE @CreateUserPersonSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
--     EXEC sp_executesql @CreateUserPersonSRTESQL;
--     PRINT 'Created database user [' + @PersonUserName + '] in NBS_SRTE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
--     BEGIN
--         DECLARE @CreateUserPersonRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
--         EXEC sp_executesql @CreateUserPersonRDBModernSQL;
--         PRINT 'Created database user [' + @PersonUserName + '] in rdb_modern';
--     END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @GrantInsertPersonSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @PersonUserName + ']';
        EXEC sp_executesql @GrantInsertPersonSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @PersonUserName + ']';
    END

PRINT 'Person service user creation completed.';

-- ==========================================
-- OBSERVATION SERVICE USER CREATION
-- ==========================================
DECLARE @ObsServiceName NVARCHAR(100) = 'observation_service';
DECLARE @ObsUserName NVARCHAR(150) = @ObsServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
-- BEGIN
--     DECLARE @CreateUserObsODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
--     EXEC sp_executesql @CreateUserObsODSESQL;
--     PRINT 'Created database user [' + @ObsUserName + '] in NBS_ODSE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
-- BEGIN
--     DECLARE @CreateUserObsSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
--     EXEC sp_executesql @CreateUserObsSRTESQL;
--     PRINT 'Created database user [' + @ObsUserName + '] in NBS_SRTE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
-- BEGIN
--     DECLARE @CreateUserInvODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
--     EXEC sp_executesql @CreateUserInvODSESQL;
--     PRINT 'Created database user [' + @InvUserName + '] in NBS_ODSE';
-- END

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

        -- Grant write permissions on MODERN tables
        DECLARE @GrantWriteSubjectRaceModernSQL NVARCHAR(MAX) = 'GRANT INSERT, UPDATE, DELETE ON [dbo].[SubjectRaceInfo_Modern] TO [' + @InvUserName + ']';
        EXEC sp_executesql @GrantWriteSubjectRaceModernSQL;
        PRINT 'Granted write permissions on [dbo].[SubjectRaceInfo_Modern] to [' + @InvUserName + ']';

        DECLARE @GrantWritePHCFactModernSQL NVARCHAR(MAX) = 'GRANT INSERT, UPDATE, DELETE ON [dbo].[PublicHealthCaseFact_Modern] TO [' + @InvUserName + ']';
        EXEC sp_executesql @GrantWritePHCFactModernSQL;
        PRINT 'Granted write permissions on [dbo].[PublicHealthCaseFact_Modern] to [' + @InvUserName + ']';
    END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
-- BEGIN
--     DECLARE @CreateUserInvSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
--     EXEC sp_executesql @CreateUserInvSRTESQL;
--     PRINT 'Created database user [' + @InvUserName + '] in NBS_SRTE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
-- BEGIN
--     DECLARE @CreateUserInvRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
--     EXEC sp_executesql @CreateUserInvRDBModernSQL;
--     PRINT 'Created database user [' + @InvUserName + '] in rdb_modern';
-- END

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

-- ==========================================
-- LDF SERVICE USER CREATION
-- ==========================================
DECLARE @LdfServiceName NVARCHAR(100) = 'ldf_service';
DECLARE @LdfUserName NVARCHAR(150) = @LdfServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
-- BEGIN
--     DECLARE @CreateUserLdfODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
--     EXEC sp_executesql @CreateUserLdfODSESQL;
--     PRINT 'Created database user [' + @LdfUserName + '] in NBS_ODSE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
-- BEGIN
--     DECLARE @CreateUserLdfSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
--     EXEC sp_executesql @CreateUserLdfSRTESQL;
--     PRINT 'Created database user [' + @LdfUserName + '] in NBS_SRTE';
-- END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
-- BEGIN
--     DECLARE @CreateUserLdfRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
--     EXEC sp_executesql @CreateUserLdfRDBModernSQL;
--     PRINT 'Created database user [' + @LdfUserName + '] in rdb_modern';
-- END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @GrantInsertLdfSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @LdfUserName + ']';
        EXEC sp_executesql @GrantInsertLdfSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @LdfUserName + ']';
    END

PRINT 'LDF service user creation completed.';

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostRDBSQL;
--         PRINT 'Created database user [' + @PostUserName + '] in rdb';
--     END

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
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostRDBModernSQL;
--         PRINT 'Created database user [' + @PostUserName + '] in rdb_modern';
--     END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostRDBModernOwnerSQL;
        PRINT 'Added [' + @PostUserName + '] to db_owner role in rdb_modern';
    END

-- Grant permissions on NBS_SRTE database (DB_DATAREADER)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostNBSSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostNBSSRTESQL;
--         PRINT 'Created database user [' + @PostUserName + '] in NBS_SRTE';
--     END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostNBSSRTEReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostNBSSRTEReaderSQL;
        PRINT 'Added [' + @PostUserName + '] to db_datareader role in NBS_SRTE';
    END

PRINT 'Post-processing service user creation completed:';
PRINT '- db_owner permissions on rdb and rdb_modern databases';
PRINT '- db_datareader permissions on NBS_SRTE database (for information schema access)';

