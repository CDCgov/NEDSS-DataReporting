--1. KAFKA SYNC CONNECTOR SERVICE PERMISSIONS
DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

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

-- 7. POST PROCESSING SERVICE PERMISSIONS
DECLARE @PostServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @PostUserName NVARCHAR(150) = @PostServiceName + '_rdb';

-- 8. DEBEZIUM SERVICE PERMISSIONS (Not required for RDB)
-- DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
-- DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';

-- ==========================================
-- PERMISSION GRANTS
-- ==========================================

-- KAFKA SYNC CONNECTOR SERVICE permission grants

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @KafkaUserName)
-- BEGIN
--     DECLARE @CreateUserKafkaRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @KafkaUserName + '] FOR LOGIN [' + @KafkaUserName + ']';
--     EXEC sp_executesql @CreateUserKafkaRDBModernSQL;
--     PRINT 'Created database user [' + @KafkaUserName + '] in rdb_modern';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @KafkaUserName)
    BEGIN
        -- Grant data writer role (INSERT, UPDATE, DELETE)
        DECLARE @AddRoleMemberKafkaRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @KafkaUserName + '''';
        EXEC sp_executesql @AddRoleMemberKafkaRDBModernWriterSQL;
        PRINT 'Added [' + @KafkaUserName + '] to db_datawriter role in rdb_modern';

        -- Grant data reader role (SELECT)
        DECLARE @AddRoleMemberKafkaRDBModernReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @KafkaUserName + '''';
        EXEC sp_executesql @AddRoleMemberKafkaRDBModernReaderSQL;
        PRINT 'Added [' + @KafkaUserName + '] to db_datareader role in rdb_modern';
    END

PRINT 'Kafka sync connector service permission grants completed.';

-- ORGANIZATION SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
-- BEGIN
--     DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
--     EXEC sp_executesql @CreateUserRDBModernSQL;
--     PRINT 'Created database user [' + @OrgUserName + '] in rdb_modern';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @GrantInsertOrgSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @OrgUserName + ']';
        EXEC sp_executesql @GrantInsertOrgSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @OrgUserName + ']';
    END

PRINT 'Organization service permission grants completed.';

-- PERSON SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
--     BEGIN
--         DECLARE @CreateUserPersonRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
--         EXEC sp_executesql @CreateUserPersonRDBModernSQL;
--         PRINT 'Created database user [' + @PersonUserName + '] in rdb_modern';
--     END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @GrantInsertPersonSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @PersonUserName + ']';
        EXEC sp_executesql @GrantInsertPersonSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @PersonUserName + ']';
    END

PRINT 'Person service permission grants completed.';

-- OBSERVATION SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
--     BEGIN
--         DECLARE @CreateUserObsRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
--         EXEC sp_executesql @CreateUserObsRDBModernSQL;
--         PRINT 'Created database user [' + @ObsUserName + '] in rdb';
--     END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @GrantInsertObsSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @ObsUserName + ']';
        EXEC sp_executesql @GrantInsertObsSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @ObsUserName + ']';
    END

PRINT 'Observation service permission grants completed.';


-- INVESTIGATION SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
-- BEGIN
--     DECLARE @CreateUserInvRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
--     EXEC sp_executesql @CreateUserInvRDBModernSQL;
--     PRINT 'Created database user [' + @InvUserName + '] in rdb';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        -- Grant data writer role
        DECLARE @AddRoleMemberInvRDBModernWriterSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datawriter'', ''' + @InvUserName + '''';
        EXEC sp_executesql @AddRoleMemberInvRDBModernWriterSQL;
        PRINT 'Added [' + @InvUserName + '] to db_datawriter role in rdb';

        -- Grant data reader role (required because db_datawriter doesn't include read permissions)
        DECLARE @AddRoleMemberInvRDBModernReaderSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @InvUserName + '''';
        EXEC sp_executesql @AddRoleMemberInvRDBModernReaderSQL;
        PRINT 'Added [' + @InvUserName + '] to db_datareader role in rdb';
    END

PRINT 'Investigation service permission grants completed.';

-- LDF SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
-- BEGIN
--     DECLARE @CreateUserLdfRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
--     EXEC sp_executesql @CreateUserLdfRDBModernSQL;
--     PRINT 'Created database user [' + @LdfUserName + '] in rdb';
-- END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @GrantInsertLdfSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @LdfUserName + ']';
        EXEC sp_executesql @GrantInsertLdfSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @LdfUserName + ']';
    END

PRINT 'LDF service permission grants completed.';


-- POST PROCESSING SERVICE PERMISSIONS

-- IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
--     BEGIN
--         DECLARE @CreateUserPostRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
--         EXEC sp_executesql @CreateUserPostRDBModernSQL;
--         PRINT 'Created database user [' + @PostUserName + '] in rdb';
--     END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostRDBModernOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostRDBModernOwnerSQL;
        PRINT 'Added [' + @PostUserName + '] to db_owner role in rdb';
    END

PRINT 'Post-processing service permission grants completed:';