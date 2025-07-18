-- 1. DEBEZIUM SERVICE PERMISSIONS
DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';

-- 2. ORGANIZATION SERVICE PERMISSIONS
DECLARE @OrgServiceName NVARCHAR(100) = 'organization_service';
DECLARE @OrgUserName NVARCHAR(150) = @OrgServiceName + '_rdb';

-- 3. PERSON SERVICE PERMISSIONS
DECLARE @PersonServiceName NVARCHAR(100) = 'person_service';
DECLARE @PersonUserName NVARCHAR(150) = @PersonServiceName + '_rdb';

-- 4. OBSERVATION SERVICE PERMISSIONS
DECLARE @ObsServiceName NVARCHAR(100) = 'observation_service';
DECLARE @ObsUserName NVARCHAR(150) = @ObsServiceName + '_rdb';

-- 5. INVESTIGATION SERVICE PERMISSIONS
DECLARE @InvServiceName NVARCHAR(100) = 'investigation_service';
DECLARE @InvUserName NVARCHAR(150) = @InvServiceName + '_rdb';

-- 6. LDF SERVICE PERMISSIONS
DECLARE @LdfServiceName NVARCHAR(100) = 'ldf_service';
DECLARE @LdfUserName NVARCHAR(150) = @LdfServiceName + '_rdb';

-- 7. KAFKA SYNC CONNECTOR SERVICE PERMISSIONS (Not required for ODSE/SRTE)
-- DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
-- DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

--8. POST PROCESSING SERVICE PERMISSIONS
DECLARE @PostServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @PostUserName NVARCHAR(150) = @PostServiceName + '_rdb';

DECLARE @ODSE_DB NVARCHAR(64) = db_name();

-- ==========================================
-- PERMISSION GRANTS
-- ==========================================

-- DEBEZIUM SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
-- BEGIN
--     DECLARE @CreateUserDebeziumODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
--     EXEC sp_executesql @CreateUserDebeziumODSESQL;
--     PRINT 'Created database user [' + @DebeziumUserName + '] in ' +@ODSE_DB;
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @AddRoleMemberDebeziumODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumODSESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in ' +@ODSE_DB;
    END
PRINT 'Debezium service user permission grants completed.';

-- ORGANIZATION SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
-- BEGIN
--     DECLARE @CreateUserODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
--     EXEC sp_executesql @CreateUserODSESQL;
--     PRINT 'Created database user [' + @OrgUserName + '] in ' +@ODSE_DB;
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @AddRoleMemberOrgODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @OrgUserName + '''';
        EXEC sp_executesql @AddRoleMemberOrgODSESQL;
        PRINT 'Added [' + @OrgUserName + '] to db_datareader role in ' +@ODSE_DB;

        DECLARE @GrantExecOrgSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_organization_event] TO [' + @OrgUserName + ']';
        EXEC sp_executesql @GrantExecOrgSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_organization_event] to [' + @OrgUserName + ']';

        DECLARE @GrantExecPlaceSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_place_event] TO [' + @OrgUserName + ']';
        EXEC sp_executesql @GrantExecPlaceSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_place_event] to [' + @OrgUserName + ']';
    END
PRINT 'Organization service user permission grants completed.';

-- PERSON SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
-- BEGIN
--     DECLARE @CreateUserPersonODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
--     EXEC sp_executesql @CreateUserPersonODSESQL;
--     PRINT 'Created database user [' + @PersonUserName + '] in ' +@ODSE_DB;
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @AddRoleMemberPersonODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PersonUserName + '''';
        EXEC sp_executesql @AddRoleMemberPersonODSESQL;
        PRINT 'Added [' + @PersonUserName + '] to db_datareader role in ' +@ODSE_DB;

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

PRINT 'Person service user permission grants completed.';


-- OBSERVATION SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
-- BEGIN
--     DECLARE @CreateUserObsODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
--     EXEC sp_executesql @CreateUserObsODSESQL;
--     PRINT 'Created database user [' + @ObsUserName + '] in ' +@ODSE_DB;
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @AddRoleMemberObsODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @ObsUserName + '''';
        EXEC sp_executesql @AddRoleMemberObsODSESQL;
        PRINT 'Added [' + @ObsUserName + '] to db_datareader role in ' +@ODSE_DB;

        DECLARE @GrantExecObsSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_observation_event] TO [' + @ObsUserName + ']';
        EXEC sp_executesql @GrantExecObsSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_observation_event] to [' + @ObsUserName + ']';
    END

PRINT 'Observation service permission grants completed.';

-- INVESTIGATION SERVICE PERMISSIONS
-- Special permissions: db_datawriter on ODSE (writes to PublicHealthCaseFact and SubjectRaceInfo)

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
-- BEGIN
--     DECLARE @CreateUserInvODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
--     EXEC sp_executesql @CreateUserInvODSESQL;
--     PRINT 'Created database user [' + @InvUserName + '] in ' +@ODSE_DB;
-- END

-- Note: Using db_datawriter because investigation service writes to PublicHealthCaseFact and SubjectRaceInfo tables
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @AddRoleMemberInvWriterODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @InvUserName + '''';
        EXEC sp_executesql @AddRoleMemberInvWriterODSESQL;
        PRINT 'Added [' + @InvUserName + '] to db_datawriter role in ' +@ODSE_DB;

        DECLARE @AddRoleMemberInvReaderODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @InvUserName + '''';
        EXEC sp_executesql @AddRoleMemberInvReaderODSESQL;
        PRINT 'Added [' + @InvUserName + '] to db_datareader role in ' +@ODSE_DB;

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

PRINT 'Investigation service permission grants completed.';

-- LDF SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
-- BEGIN
--     DECLARE @CreateUserLdfODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
--     EXEC sp_executesql @CreateUserLdfODSESQL;
--     PRINT 'Created database user [' + @LdfUserName + '] in ' +@ODSE_DB;
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @AddRoleMemberLdfODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @LdfUserName + '''';
        EXEC sp_executesql @AddRoleMemberLdfODSESQL;
        PRINT 'Added [' + @LdfUserName + '] to db_datareader role in ' +@ODSE_DB;

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

PRINT 'LDF service permission grants completed.';


-- POST PROCESSING SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostRDBModernSQL;
--         PRINT 'Created database user [' + @PostUserName + '] in ' +@RDB_DB;
--     END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostRDBModernOwnerSQL;
        PRINT 'Added [' + @PostUserName + '] to db_datareader role in ' +@ODSE_DB;
    END

PRINT 'Post-processing service permission grants completed:';