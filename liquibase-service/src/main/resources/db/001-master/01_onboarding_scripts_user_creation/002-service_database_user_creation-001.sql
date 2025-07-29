-- ====================================================
-- USER CREATION FOR RTR SERVICES
-- Scripts create required users in each database.
-- ====================================================

-- 1. DEBEZIUM SERVICE USER
DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';

-- 2. KAFKA SYNC CONNECTOR SERVICE USER
DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

-- 3. ORGANIZATION SERVICE USER
DECLARE @OrgServiceName NVARCHAR(100) = 'organization_service';
DECLARE @OrgUserName NVARCHAR(150) = @OrgServiceName + '_rdb';

-- 4. PERSON SERVICE USER
DECLARE @PersonServiceName NVARCHAR(100) = 'person_service';
DECLARE @PersonUserName NVARCHAR(150) = @PersonServiceName + '_rdb';

-- 5. OBSERVATION SERVICE USER
DECLARE @ObsServiceName NVARCHAR(100) = 'observation_service';
DECLARE @ObsUserName NVARCHAR(150) = @ObsServiceName + '_rdb';

-- 6. INVESTIGATION SERVICE USER
DECLARE @InvServiceName NVARCHAR(100) = 'investigation_service';
DECLARE @InvUserName NVARCHAR(150) = @InvServiceName + '_rdb';

-- 7. LDF SERVICE USER
DECLARE @LdfServiceName NVARCHAR(100) = 'ldf_service';
DECLARE @LdfUserName NVARCHAR(150) = @LdfServiceName + '_rdb';

-- 8. POST PROCESSING SERVICE USER
DECLARE @PostServiceName NVARCHAR(100) = 'post_processing_service';
DECLARE @PostUserName NVARCHAR(150) = @PostServiceName + '_rdb';


-- ==========================================
-- NBS_ODSE USER CREATION
-- ==========================================

USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';
DECLARE @ODSE_DB NVARCHAR(128) = db_name()

-- 1. DEBEZIUM SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @CreateUserDebeziumODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
        EXEC sp_executesql @CreateUserDebeziumODSESQL;
        PRINT 'Created database user [' + @DebeziumUserName + '] in ' +@ODSE_DB;
    END

-- 2. ORGANIZATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @CreateUserOrgODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
        EXEC sp_executesql @CreateUserOrgODSESQL;
        PRINT 'Created database user [' + @OrgUserName + '] in ' +@ODSE_DB;
    END

-- 3. PERSON SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @CreateUserPersonODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
        EXEC sp_executesql @CreateUserPersonODSESQL;
        PRINT 'Created database user [' + @PersonUserName + '] in ' +@ODSE_DB;
    END

-- 4. OBSERVATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @CreateUserObsODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
        EXEC sp_executesql @CreateUserObsODSESQL;
        PRINT 'Created database user [' + @ObsUserName + '] in ' +@ODSE_DB;
    END

-- 5. INVESTIGATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @CreateUserInvODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
        EXEC sp_executesql @CreateUserInvODSESQL;
        PRINT 'Created database user [' + @InvUserName + '] in ' +@ODSE_DB;
    END

-- 6. LDF SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @CreateUserLdfODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
        EXEC sp_executesql @CreateUserLdfODSESQL;
        PRINT 'Created database user [' + @LdfUserName + '] in ' +@ODSE_DB;
    END

-- ==========================================
-- NBS_SRTE USER CREATION
-- ==========================================
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';
DECLARE @SRTE_DB NVARCHAR(128) = db_name()

-- 1. DEBEZIUM SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @CreateUserDebeziumSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
        EXEC sp_executesql @CreateUserDebeziumSRTESQL;
        PRINT 'Created database user [' + @DebeziumUserName + '] in ' +@SRTE_DB;
    END

-- 2. ORGANIZATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @CreateUserOrgSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
        EXEC sp_executesql @CreateUserOrgSRTESQL;
        PRINT 'Created database user [' + @OrgUserName + '] in ' +@SRTE_DB;
    END

-- 3. PERSON SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @CreateUserPersonSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
        EXEC sp_executesql @CreateUserPersonSRTESQL;
        PRINT 'Created database user [' + @PersonUserName + '] in ' +@SRTE_DB;
    END

-- 4. OBSERVATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @CreateUserObsSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
        EXEC sp_executesql @CreateUserObsSRTESQL;
        PRINT 'Created database user [' + @ObsUserName + '] in ' +@SRTE_DB;
    END

-- 5. INVESTIGATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @CreateUserInvSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
        EXEC sp_executesql @CreateUserInvSRTESQL;
        PRINT 'Created database user [' + @InvUserName + '] in ' +@SRTE_DB;
    END

-- 6. LDF SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @CreateUserLdfSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
        EXEC sp_executesql @CreateUserLdfSRTESQL;
        PRINT 'Created database user [' + @LdfUserName + '] in ' +@SRTE_DB;
    END

-- 7. POST PROCESSING SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @CreateUserPostNBSSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
        EXEC sp_executesql @CreateUserPostNBSSRTESQL;
        PRINT 'Created database user [' + @PostUserName + '] in ' +@SRTE_DB;
    END

-- ==========================================
-- RDB USER CREATION
-- ==========================================

IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
    BEGIN
        USE rdb_modern;
        PRINT 'Switched to database rdb_modern'
    END
ELSE
    BEGIN
        USE rdb;
        PRINT 'Switched to database rdb';
    END

DECLARE @RDB_DB NVARCHAR(128) = db_name()

-- 1. KAFKA SYNC CONNECTOR SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @KafkaUserName)
    BEGIN
        DECLARE @CreateUserKafkaRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @KafkaUserName + '] FOR LOGIN [' + @KafkaUserName + ']';
        EXEC sp_executesql @CreateUserKafkaRDBModernSQL;
        PRINT 'Created database user [' + @KafkaUserName + '] in ' +@RDB_DB;
    END

-- 2. ORGANIZATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @OrgUserName)
    BEGIN
        DECLARE @CreateUserRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @OrgUserName + '] FOR LOGIN [' + @OrgUserName + ']';
        EXEC sp_executesql @CreateUserRDBModernSQL;
        PRINT 'Created database user [' + @OrgUserName + '] in ' +@RDB_DB;
    END

-- 3. PERSON SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PersonUserName)
    BEGIN
        DECLARE @CreateUserPersonRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @PersonUserName + '] FOR LOGIN [' + @PersonUserName + ']';
        EXEC sp_executesql @CreateUserPersonRDBModernSQL;
        PRINT 'Created database user [' + @PersonUserName + '] in ' +@RDB_DB;
    END

-- 4. OBSERVATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @ObsUserName)
    BEGIN
        DECLARE @CreateUserObsRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @ObsUserName + '] FOR LOGIN [' + @ObsUserName + ']';
        EXEC sp_executesql @CreateUserObsRDBModernSQL;
        PRINT 'Created database user [' + @ObsUserName + '] in ' +@RDB_DB;
    END

-- 5. INVESTIGATION SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @InvUserName)
    BEGIN
        DECLARE @CreateUserInvRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @InvUserName + '] FOR LOGIN [' + @InvUserName + ']';
        EXEC sp_executesql @CreateUserInvRDBModernSQL;
        PRINT 'Created database user [' + @InvUserName + '] in ' +@RDB_DB;
    END

-- 6. LDF SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @LdfUserName)
    BEGIN
        DECLARE @CreateUserLdfRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @LdfUserName + '] FOR LOGIN [' + @LdfUserName + ']';
        EXEC sp_executesql @CreateUserLdfRDBModernSQL;
        PRINT 'Created database user [' + @LdfUserName + '] in ' +@RDB_DB;
    END

-- 7. POST PROCESSING SERVICE USER CREATION
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @PostUserName)
    BEGIN
        DECLARE @CreateUserPostRDBSQL NVARCHAR(MAX) = 'CREATE USER [' + @PostUserName + '] FOR LOGIN [' + @PostUserName + ']';
        EXEC sp_executesql @CreateUserPostRDBSQL;
        PRINT 'Created database user [' + @PostUserName + '] in ' +@RDB_DB;
    END