-- ==========================================
-- RTR Liquibase Admin Setup
-- $(RTR_ADMIN_NAME) (Liquibase Onboarding & Migrations)
-- ==========================================

USE [master];
GO

-- ------------------------------------------
-- 1. Login Setup
-- ------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = '$(RTR_ADMIN_NAME)')
BEGIN
    CREATE LOGIN [$(RTR_ADMIN_NAME)] WITH PASSWORD = N'$(RTR_ADMIN_PASSWORD)', DEFAULT_DATABASE = [master], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;
    PRINT 'Created login [$(RTR_ADMIN_NAME)]';
END

-- ------------------------------------------
-- 2. Database-Level Permissions: NBS_ODSE
-- ------------------------------------------
IF DB_ID('NBS_ODSE') IS NOT NULL
BEGIN
    EXEC('
        USE [NBS_ODSE];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_ADMIN_NAME)'')
            CREATE USER [$(RTR_ADMIN_NAME)] FOR LOGIN [$(RTR_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(RTR_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 3. Database-Level Permissions: RDB
-- ------------------------------------------
IF DB_ID('RDB') IS NOT NULL
BEGIN
    EXEC('
        USE [RDB];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_ADMIN_NAME)'')
            CREATE USER [$(RTR_ADMIN_NAME)] FOR LOGIN [$(RTR_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(RTR_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 4. Database-Level Permissions: RDB_MODERN
-- ------------------------------------------
IF DB_ID('rdb_modern') IS NOT NULL
BEGIN
    EXEC('
        USE [rdb_modern];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(RTR_ADMIN_NAME)'')
            CREATE USER [$(RTR_ADMIN_NAME)] FOR LOGIN [$(RTR_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(RTR_ADMIN_NAME)];
    ');
END

GO
