-- DEBEZIUM SERVICE PERMISSIONS
DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';

-- KAFKA SYNC CONNECTOR SERVICE PERMISSIONS (Not required for SRTE)
-- DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
-- DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

-- ORGANIZATION SERVICE PERMISSIONS
DECLARE @OrgServiceName NVARCHAR(100) = 'organization_service';
DECLARE @OrgUserName NVARCHAR(150) = @OrgServiceName + '_rdb';

-- PERSON SERVICE PERMISSIONS
DECLARE @PersonServiceName NVARCHAR(100) = 'person_service';
DECLARE @PersonUserName NVARCHAR(150) = @PersonServiceName + '_rdb';

-- OBSERVATION SERVICE PERMISSIONS
DECLARE @ObsServiceName NVARCHAR(100) = 'observation_service';
DECLARE @ObsUserName NVARCHAR(150) = @ObsServiceName + '_rdb';

-- INVESTIGATION SERVICE PERMISSIONS
DECLARE @InvServiceName NVARCHAR(100) = 'investigation_service';
DECLARE @InvUserName NVARCHAR(150) = @InvServiceName + '_rdb';

-- LDF SERVICE PERMISSIONS
DECLARE @LdfServiceName NVARCHAR(100) = 'ldf_service';
DECLARE @LdfUserName NVARCHAR(150) = @LdfServiceName + '_rdb';

-- POST PROCESSING SERVICE PERMISSIONS
DECLARE @PostServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @PostUserName NVARCHAR(150) = @PostServiceName + '_rdb';

-- ==========================================
-- PERMISSION GRANTS
-- ==========================================

-- DEBEZIUM SERVICE PERMISSIONS
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
-- BEGIN
--     DECLARE @CreateUserDebeziumSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
--     EXEC sp_executesql @CreateUserDebeziumSRTESQL;
--     PRINT 'Created database user [' + @DebeziumUserName + '] in NBS_SRTE';
-- END
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @AddRoleMemberDebeziumSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumSRTESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in NBS_SRTE';
    END
PRINT 'Debezium service user permission grants completed.';

-- ORGANIZATION SERVICE PERMISSIONS
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
-- BEGIN
--     DECLARE @CreateUserSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
--     EXEC sp_executesql @CreateUserSRTESQL;
--     PRINT 'Created database user [' + @OrgUserName + '] in NBS_SRTE';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @AddRoleMemberOrgSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @OrgUserName + '''';
        EXEC sp_executesql @AddRoleMemberOrgSRTESQL;
        PRINT 'Added [' + @OrgUserName + '] to db_datareader role in NBS_SRTE';
    END
PRINT 'Organization service user permission grants completed.';

-- PERSON SERVICE PERMISSIONS
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
-- BEGIN
--     DECLARE @CreateUserPersonSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
--     EXEC sp_executesql @CreateUserPersonSRTESQL;
--     PRINT 'Created database user [' + @PersonUserName + '] in NBS_SRTE';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @AddRoleMemberPersonSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PersonUserName + '''';
        EXEC sp_executesql @AddRoleMemberPersonSRTESQL;
        PRINT 'Added [' + @PersonUserName + '] to db_datareader role in NBS_SRTE';
    END
PRINT 'Person service user permission grants completed.';

-- OBSERVATION SERVICE PERMISSIONS
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
-- BEGIN
--     DECLARE @CreateUserObsSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
--     EXEC sp_executesql @CreateUserObsSRTESQL;
--     PRINT 'Created database user [' + @ObsUserName + '] in NBS_SRTE';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @AddRoleMemberObsSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @ObsUserName + '''';
        EXEC sp_executesql @AddRoleMemberObsSRTESQL;
        PRINT 'Added [' + @ObsUserName + '] to db_datareader role in NBS_SRTE';
    END
PRINT 'Observation service permission grants completed.';

-- INVESTIGATION SERVICE PERMISSIONS
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
-- BEGIN
--     DECLARE @CreateUserInvSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
--     EXEC sp_executesql @CreateUserInvSRTESQL;
--     PRINT 'Created database user [' + @InvUserName + '] in NBS_SRTE';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @AddRoleMemberInvSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @InvUserName + '''';
        EXEC sp_executesql @AddRoleMemberInvSRTESQL;
        PRINT 'Added [' + @InvUserName + '] to db_datareader role in NBS_SRTE';
    END
PRINT 'Investigation service permission grants completed.';

-- LDF SERVICE PERMISSIONS
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
-- BEGIN
--     DECLARE @CreateUserLdfSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
--     EXEC sp_executesql @CreateUserLdfSRTESQL;
--     PRINT 'Created database user [' + @LdfUserName + '] in NBS_SRTE';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @AddRoleMemberLdfSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @LdfUserName + '''';
        EXEC sp_executesql @AddRoleMemberLdfSRTESQL;
        PRINT 'Added [' + @LdfUserName + '] to db_datareader role in NBS_SRTE';
    END
PRINT 'LDF service permission grants completed.';

-- POST PROCESSING SERVICE PERMISSIONS
-- Special permissions:
-- - db_datareader on NBS_SRTE (access to information schema for stored procedures)
-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostNBSSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostNBSSRTESQL;
--         PRINT 'Created database user [' + @PostUserName + '] in NBS_SRTE';
--     END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostNBSSRTEReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostNBSSRTEReaderSQL;
        PRINT 'Added [' + @PostUserName + '] to db_datareader role in NBS_SRTE';
    END

PRINT '- db_datareader permissions on NBS_SRTE database (for information schema access)';

