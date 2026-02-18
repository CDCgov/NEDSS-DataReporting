-- This script to be run outside of Automation as a one time admin user creation.
-- Restore scripts require UAT configuration to target RDB_MODERN
INSERT INTO
	NBS_ODSE.DBO.NBS_configuration (
	config_key,
	config_value,
	version_ctrl_nbr,
	add_user_id,
	add_time,
	last_chg_user_id,
	last_chg_time,
	status_cd,
	status_time
	)
VALUES
	('ENV', 'UAT', 1, 99999999, GETDATE(), 99999999, GETDATE(), 'A', GETDATE());

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

        GRANT SELECT ON msdb.dbo.sysjobs TO db_deploy_admin;
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

-- SQL Script to create service logins for all microservices at server level
-- This script creates logins for all microservices separately from user creation
-- Please provide a generated password for the UserPassword field.

USE [master];

-- Create login for debezium service
DECLARE @ServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @UserPassword NVARCHAR(128) = N'<to_be_reset_later>'; --Please provide your generated password.
DECLARE @UserName NVARCHAR(150) = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        DECLARE @CreateLoginSQL NVARCHAR(MAX) = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';

        -- Grant server-level permissions
        DECLARE @PermissionGrantSQL NVARCHAR(MAX) = 'GRANT VIEW SERVER STATE TO [' + @UserName + ']';
        EXEC sp_executesql @PermissionGrantSQL;
        PRINT 'Granted VIEW SERVER STATE permission to [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for kafka sync connector service
SET @ServiceName = 'kafka_sync_connector_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for post processing service
SET @ServiceName = 'post_processing_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for ldf service
SET @ServiceName = 'ldf_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for investigation service
SET @ServiceName = 'investigation_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for person service
SET @ServiceName = 'person_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for observation service
SET @ServiceName = 'observation_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- Create login for organization service
SET @ServiceName = 'organization_service';
SET @UserPassword = N'<to_be_reset_later>'; --Please provide your generated password.
SET @UserName = @ServiceName + '_rdb';

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        SET @CreateLoginSQL = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateLoginSQL;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

PRINT 'Service logins creation completed at server level.';

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

-- Fix for missing columns
ALTER TABLE LDF_GROUP ADD BUSINESS_OBJECT_UID BIGINT NULL;
ALTER TABLE D_VACCINATION ADD VACCINATION_UID BIGINT NULL;