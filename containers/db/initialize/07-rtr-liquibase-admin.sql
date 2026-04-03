-- ==========================================
-- RTR Liquibase Admin Setup
-- $(LIQUIBASE_ADMIN_NAME) (Liquibase Onboarding & Migrations)
-- ==========================================

USE [master];
GO

-- ------------------------------------------
-- 1. Login Setup
-- ------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = '$(LIQUIBASE_ADMIN_NAME)')
BEGIN
    CREATE LOGIN [$(LIQUIBASE_ADMIN_NAME)] WITH PASSWORD = N'$(LIQUIBASE_ADMIN_PASSWORD)', DEFAULT_DATABASE = [master], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;
    
    -- On Local SQL Server, grant sysadmin to allow CDC and Job management
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE NAME = 'rdsadmin')
    BEGIN
        ALTER SERVER ROLE [sysadmin] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
        PRINT 'Granted [sysadmin] to [$(LIQUIBASE_ADMIN_NAME)] (Local Instance)';
    END
    ELSE
    BEGIN
        -- On RDS, grant restricted server roles
        ALTER SERVER ROLE [setupadmin] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
        ALTER SERVER ROLE [processadmin] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
        GRANT ALTER ANY LOGIN TO [$(LIQUIBASE_ADMIN_NAME)];
        GRANT CREATE ANY DATABASE TO [$(LIQUIBASE_ADMIN_NAME)];
        GRANT VIEW SERVER STATE TO [$(LIQUIBASE_ADMIN_NAME)];
        PRINT 'Granted restricted deployment privileges to [$(LIQUIBASE_ADMIN_NAME)] (RDS)';
    END
END

-- ------------------------------------------
-- 2. Database-Level Permissions: NBS_ODSE
-- ------------------------------------------
IF DB_ID('NBS_ODSE') IS NOT NULL
BEGIN
    EXEC('
        USE [NBS_ODSE];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(LIQUIBASE_ADMIN_NAME)'')
            CREATE USER [$(LIQUIBASE_ADMIN_NAME)] FOR LOGIN [$(LIQUIBASE_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 3. Database-Level Permissions: NBS_SRTE
-- ------------------------------------------
IF DB_ID('NBS_SRTE') IS NOT NULL
BEGIN
    EXEC('
        USE [NBS_SRTE];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(LIQUIBASE_ADMIN_NAME)'')
            CREATE USER [$(LIQUIBASE_ADMIN_NAME)] FOR LOGIN [$(LIQUIBASE_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 4. Database-Level Permissions: RDB
-- ------------------------------------------
IF DB_ID('RDB') IS NOT NULL
BEGIN
    EXEC('
        USE [RDB];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(LIQUIBASE_ADMIN_NAME)'')
            CREATE USER [$(LIQUIBASE_ADMIN_NAME)] FOR LOGIN [$(LIQUIBASE_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 5. Database-Level Permissions: RDB_MODERN
-- ------------------------------------------
IF DB_ID('rdb_modern') IS NOT NULL
BEGIN
    EXEC('
        USE [rdb_modern];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(LIQUIBASE_ADMIN_NAME)'')
            CREATE USER [$(LIQUIBASE_ADMIN_NAME)] FOR LOGIN [$(LIQUIBASE_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 6. Database-Level Permissions: NBS_MSGOUTE
-- ------------------------------------------
IF DB_ID('NBS_MSGOUTE') IS NOT NULL
BEGIN
    EXEC('
        USE [NBS_MSGOUTE];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(LIQUIBASE_ADMIN_NAME)'')
            CREATE USER [$(LIQUIBASE_ADMIN_NAME)] FOR LOGIN [$(LIQUIBASE_ADMIN_NAME)];
        ALTER ROLE [db_owner] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
    ');
END

-- ------------------------------------------
-- 7. msdb Permissions
-- ------------------------------------------
IF DB_ID('msdb') IS NOT NULL
BEGIN
    EXEC('
        USE [msdb];
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = ''$(LIQUIBASE_ADMIN_NAME)'')
            CREATE USER [$(LIQUIBASE_ADMIN_NAME)] FOR LOGIN [$(LIQUIBASE_ADMIN_NAME)];
        
        ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [$(LIQUIBASE_ADMIN_NAME)];
        GRANT SELECT ON msdb.dbo.sysjobs TO [$(LIQUIBASE_ADMIN_NAME)];
        
        -- RDS specific grants (ignored if procedure doesn''t exist)
        IF EXISTS (SELECT 1 FROM sys.objects WHERE name = ''rds_cdc_enable_db'')
        BEGIN
            GRANT EXECUTE ON msdb.dbo.rds_cdc_enable_db TO [$(LIQUIBASE_ADMIN_NAME)];
            GRANT EXECUTE ON msdb.dbo.rds_cdc_disable_db TO [$(LIQUIBASE_ADMIN_NAME)];
        END
    ');
END
GO
