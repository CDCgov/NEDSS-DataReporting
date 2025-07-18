-- This script to be run outside of Automation as a one time admin user creation.
-- Please provide a generated password for the PASSWORD field.
USE [master]
IF NOT EXISTS (SELECT name
               FROM sys.server_principals
               WHERE name = 'db_deploy_admin')
    BEGIN
        CREATE LOGIN [db_deploy_admin] WITH PASSWORD =N'<to_be_reset_later>', DEFAULT_DATABASE = [master], DEFAULT_LANGUAGE = [us_english], CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;

        ALTER SERVER ROLE [setupadmin] ADD MEMBER [db_deploy_admin];

        ALTER SERVER ROLE [processadmin] ADD MEMBER [db_deploy_admin];

        GRANT ALTER ANY CREDENTIAL TO [db_deploy_admin];

        GRANT ALTER ANY LOGIN TO [db_deploy_admin];

        GRANT CREATE ANY DATABASE TO [db_deploy_admin];

        GRANT VIEW SERVER STATE TO [db_deploy_admin];

    END

if exists (select 1
           from sys.databases
           where name = 'rdsadmin') -- for aws
    begin
        USE msdb;

        IF NOT EXISTS (SELECT name FROM master.sys.database_principals WHERE name = 'db_deploy_admin')
        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo];

        GRANT EXECUTE ON msdb.dbo.rds_cdc_enable_db TO db_deploy_admin;

        GRANT EXECUTE ON msdb.dbo.rds_cdc_disable_db TO db_deploy_admin;

        /*
            CNDE-2707:

            For AWS RDS deployments, SQLAgentOperatorRole must be granted explicitly. For Azure and onprem,
            it is sufficient to just have sysadmin role, which has full access to SQL Server Agent roles.
        */

        ALTER ROLE [SQLAgentOperatorRole] ADD MEMBER [db_deploy_admin];
    end;
else
    begin
        -- azure and onprem
        ALTER SERVER ROLE [sysadmin] ADD MEMBER [db_deploy_admin]

        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]
        GRANT EXECUTE ON sys.sp_cdc_enable_db TO db_deploy_admin;
        GRANT EXECUTE ON sys.sp_cdc_disable_db TO db_deploy_admin;
    end;


USE [RDB];

IF NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
    BEGIN
        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]
        ALTER ROLE [db_owner] ADD MEMBER [db_deploy_admin]
    END;

USE [rdb_modern];

IF NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
    BEGIN
        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]

        ALTER ROLE [db_owner] ADD MEMBER [db_deploy_admin]
    END

USE [nbs_odse];


IF NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
    BEGIN
        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]

        ALTER ROLE [db_owner] ADD MEMBER [db_deploy_admin]
    END;

USE [nbs_srte];

IF NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
    BEGIN
        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]

        ALTER ROLE [db_owner] ADD MEMBER [db_deploy_admin]
    END;

USE [nbs_msgoute]


IF NOT EXISTS (SELECT *
               FROM sys.database_principals
               WHERE name = 'db_deploy_admin')
    BEGIN
        CREATE USER [db_deploy_admin] FOR LOGIN [db_deploy_admin] WITH DEFAULT_SCHEMA =[dbo]


        ALTER ROLE [db_owner] ADD MEMBER [db_deploy_admin]
    end;


-- ALTER LOGIN db_deploy_admin with password ='<your new pass>';
