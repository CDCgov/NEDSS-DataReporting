--Only required where rdb and rdb_modern both exist.

-- --1. KAFKA SYNC CONNECTOR SERVICE PERMISSIONS
-- DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
-- DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

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

DECLARE @RDB_DB NVARCHAR(64) = db_name()

-- ==========================================
-- PERMISSION GRANTS
-- ==========================================

-- POST PROCESSING SERVICE PERMISSIONS

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @CreateUserPostRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
        EXEC sp_executesql @CreateUserPostRDBSQL;
        PRINT 'Created database user [' + @PostUserName + '] in ' +@RDB_DB;
    END

-- Grant permissions (always execute regardless of user creation)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @AddRoleMemberPostRDBOwnerSQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_owner'', ''' + @PostUserName + '''';
        EXEC sp_executesql @AddRoleMemberPostRDBOwnerSQL;
        PRINT 'Added [' + @PostUserName + '] to db_owner role in ' +@RDB_DB;
    END

PRINT 'Post-processing service permission grants completed:';

-- ORGANIZATION SERVICE PERMISSIONS

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
        EXEC sp_executesql @CreateUserRDBModernSQL;
        PRINT 'Created database user [' + @OrgUserName + '] in ' +@RDB_DB;
    END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @GrantInsertOrgSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @OrgUserName + ']';
        EXEC sp_executesql @GrantInsertOrgSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @OrgUserName + ']';
    END

PRINT 'Organization service permission grants completed.';

-- PERSON SERVICE PERMISSIONS

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @CreateUserPersonRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
        EXEC sp_executesql @CreateUserPersonRDBModernSQL;
        PRINT 'Created database user [' + @PersonUserName + '] in ' +@RDB_DB;
    END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @GrantInsertPersonSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @PersonUserName + ']';
        EXEC sp_executesql @GrantInsertPersonSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @PersonUserName + ']';
    END

PRINT 'Person service permission grants completed.';

-- OBSERVATION SERVICE PERMISSIONS

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @CreateUserObsRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
        EXEC sp_executesql @CreateUserObsRDBModernSQL;
        PRINT 'Created database user [' + @ObsUserName + '] in ' +@RDB_DB;
    END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @GrantInsertObsSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @ObsUserName + ']';
        EXEC sp_executesql @GrantInsertObsSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @ObsUserName + ']';
    END

PRINT 'Observation service permission grants completed.';


-- LDF SERVICE PERMISSIONS

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @CreateUserLdfRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
        EXEC sp_executesql @CreateUserLdfRDBModernSQL;
        PRINT 'Created database user [' + @LdfUserName + '] in ' +@RDB_DB;
    END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @GrantInsertLdfSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @LdfUserName + ']';
        EXEC sp_executesql @GrantInsertLdfSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @LdfUserName + ']';
    END

PRINT 'LDF service permission grants completed.';


IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @CreateUserInvRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
        EXEC sp_executesql @CreateUserInvRDBModernSQL;
        PRINT 'Created database user [' + @InvUserName + '] in ' +@RDB_DB;
    END

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @GrantInsertInvSQL NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @InvUserName + ']';
        EXEC sp_executesql @GrantInsertInvSQL;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @InvUserName + ']';
    END

PRINT 'RDB service permission grants completed.';