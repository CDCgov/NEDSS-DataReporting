-- ==========================================
-- KAFKA SYNC CONNECTOR SERVICE USER CREATION
-- ==========================================
DECLARE @KafkaServiceName NVARCHAR(100) = 'kafka_sync_connector_service';
DECLARE @KafkaUserName NVARCHAR(150) = @KafkaServiceName + '_rdb';

-- Grant permissions on RDB_modern database (READ + WRITE)
USE [rdb_modern];
PRINT 'Switched to database [rdb_modern]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @KafkaUserName)
    BEGIN
        DECLARE @CreateUserKafkaRDBModernSQL NVARCHAR(MAX) = 'CREATE USER [' + @KafkaUserName + '] FOR LOGIN [' + @KafkaUserName + ']';
        EXEC sp_executesql @CreateUserKafkaRDBModernSQL;
        PRINT 'Created database user [' + @KafkaUserName + '] in rdb_modern';
    END

-- Grant permissions (always execute regardless of user creation)
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

PRINT 'Kafka sync connector service user creation completed with READ + WRITE permissions.';