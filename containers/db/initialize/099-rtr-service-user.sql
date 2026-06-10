-- ==========================================
-- RTR Service User Setup
-- $(RTR_SERVICE_USER_NAME) (Debezium, Kafka, Java Services)
-- ==========================================

USE [master];
GO

-- ------------------------------------------
-- 1. Login Setup
-- ------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = '$(RTR_SERVICE_USER_NAME)')
BEGIN
    CREATE LOGIN [$(RTR_SERVICE_USER_NAME)] WITH PASSWORD = N'$(RTR_SERVICE_USER_PASSWORD)', DEFAULT_DATABASE = [master], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;
    GRANT VIEW SERVER STATE TO [$(RTR_SERVICE_USER_NAME)];
    PRINT 'Created login [$(RTR_SERVICE_USER_NAME)] and granted VIEW SERVER STATE';
END

-- ------------------------------------------
-- 2. Database-Level Permissions: NBS_ODSE
-- ------------------------------------------
IF DB_ID('NBS_ODSE') IS NOT NULL
BEGIN
    EXEC('
        USE [NBS_ODSE];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_SERVICE_USER_NAME)'')
            CREATE USER [$(RTR_SERVICE_USER_NAME)] FOR LOGIN [$(RTR_SERVICE_USER_NAME)];
        ALTER ROLE [db_datareader] ADD MEMBER [$(RTR_SERVICE_USER_NAME)];
        GRANT INSERT, UPDATE, DELETE ON [dbo].[SubjectRaceInfo] TO [$(RTR_SERVICE_USER_NAME)];
        GRANT INSERT, UPDATE, DELETE ON [dbo].[PublicHealthCaseFact] TO [$(RTR_SERVICE_USER_NAME)];
    ');
END

-- ------------------------------------------
-- 3. Database-Level Permissions: NBS_SRTE
-- ------------------------------------------
IF DB_ID('NBS_SRTE') IS NOT NULL
BEGIN
    EXEC('
        USE [NBS_SRTE];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_SERVICE_USER_NAME)'')
            CREATE USER [$(RTR_SERVICE_USER_NAME)] FOR LOGIN [$(RTR_SERVICE_USER_NAME)];
        ALTER ROLE [db_datareader] ADD MEMBER [$(RTR_SERVICE_USER_NAME)];
    ');
END

-- ------------------------------------------
-- 4. Database-Level Permissions: RDB
-- ------------------------------------------
IF DB_ID('RDB') IS NOT NULL
BEGIN
    EXEC('
        USE [RDB];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_SERVICE_USER_NAME)'')
            CREATE USER [$(RTR_SERVICE_USER_NAME)] FOR LOGIN [$(RTR_SERVICE_USER_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(RTR_SERVICE_USER_NAME)];
    ');
END

-- ------------------------------------------
-- 5. Database-Level Permissions: RDB_MODERN
-- ------------------------------------------
IF DB_ID('rdb_modern') IS NOT NULL
BEGIN
    EXEC('
        USE [rdb_modern];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_SERVICE_USER_NAME)'')
            CREATE USER [$(RTR_SERVICE_USER_NAME)] FOR LOGIN [$(RTR_SERVICE_USER_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(RTR_SERVICE_USER_NAME)];
    ');
END
GO
