-- ==========================================
-- USER: person_service_rdb
-- SERVICE: person-service
-- ==========================================
USE [master];

DECLARE @UserName NVARCHAR(150) = 'person_service_rdb';
DECLARE @UserPassword NVARCHAR(128) = N'person_service'; --Please provide your generated password.

-- Check if login already exists before creating
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = @UserName)
    BEGIN
        -- Create the login at server level
        DECLARE @CreateMasterLogin NVARCHAR(MAX) = 'CREATE LOGIN [' + @UserName + '] WITH PASSWORD=N''' + @UserPassword + ''', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF';
        EXEC sp_executesql @CreateMasterLogin;
        PRINT 'Created login [' + @UserName + ']';
    END
ELSE
    BEGIN
        PRINT 'Login [' + @UserName + '] already exists';
    END

-- ==========================================
-- NBS_ODSE
-- ==========================================
USE [NBS_ODSE];

-- Create user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @CreateOdseUser NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateOdseUser;
        PRINT 'Created database user [' + @UserName + '] in NBS_ODSE';
    END

-- Add permissions
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Grant data reader role
        DECLARE @AddOdseRoleReader NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddOdseRoleReader;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_ODSE';

        -- Grant update permissions on SubjectRaceInfo
        DECLARE @GrantOdseWriteSubjectRaceSQL NVARCHAR(MAX) = 'GRANT UPDATE ON [dbo].[SubjectRaceInfo] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantOdseWriteSubjectRaceSQL;
        PRINT 'Granted write permissions on [dbo].[SubjectRaceInfo] to [' + @UserName + ']';

        -- Grant update permissions on PublicHealthCaseFact
        DECLARE @GrantOdseWritePHCFactSQL NVARCHAR(MAX) = 'GRANT UPDATE ON [dbo].[PublicHealthCaseFact] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantOdseWritePHCFactSQL;
        PRINT 'Granted write permissions on [dbo].[PublicHealthCaseFact] to [' + @UserName + ']';
    END

-- ==========================================
-- NBS_SRTE
-- ==========================================
USE [NBS_SRTE];

-- Create user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @CreateSrteUser NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateSrteUser;
        PRINT 'Created database user [' + @UserName + '] in NBS_SRTE';
    END

-- Add permissions
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Grant data reader role
        DECLARE @AddSrteRoleReader NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @UserName + '''';
        EXEC sp_executesql @AddSrteRoleReader;
        PRINT 'Added [' + @UserName + '] to db_datareader role in NBS_SRTE';
    END

-- ==========================================
-- RDB / RDB_MODERN
-- ==========================================
-- Switch to configured RTR target database
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

-- Create user
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        DECLARE @CreateRdbUser NVARCHAR(MAX) = 'CREATE USER [' + @UserName + '] FOR LOGIN [' + @UserName + ']';
        EXEC sp_executesql @CreateRdbUser;
        PRINT 'Created database user [' + @UserName + '] in ' +@RDB_DB;
    END

-- Add permissions
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @UserName)
    BEGIN
        -- Grant data writer for job_flow_log
        DECLARE @AddRdbRoleWriterJobFlowLog NVARCHAR(MAX) = 'GRANT INSERT ON [dbo].[job_flow_log] TO [' + @UserName + ']';
        EXEC sp_executesql @AddRdbRoleWriterJobFlowLog;
        PRINT 'Granted INSERT permission on [dbo].[job_flow_log] to [' + @UserName + ']';
        
        -- Grant execute for stored procedures
        DECLARE @GrantExecPatientSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_patient_event] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantExecPatientSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_patient_event] to [' + @UserName + ']';

        DECLARE @GrantExecRaceSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_patient_race_event] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantExecRaceSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_patient_race_event] to [' + @UserName + ']';

        DECLARE @GrantExecProviderSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_provider_event] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantExecProviderSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_provider_event] to [' + @UserName + ']';

        DECLARE @GrantExecAuthUserSPSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_auth_user_event] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantExecAuthUserSPSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_auth_user_event] to [' + @UserName + ']';

        DECLARE @GrantPersonExecPHCDatamartUpdateSQL NVARCHAR(MAX) = 'GRANT EXECUTE ON [dbo].[sp_public_health_case_fact_datamart_update] TO [' + @UserName + ']';
        EXEC sp_executesql @GrantPersonExecPHCDatamartUpdateSQL;
        PRINT 'Granted EXECUTE permission on [dbo].[sp_public_health_case_fact_datamart_update] to [' + @UserName + ']';
    END

PRINT 'Person service permission grants completed.';
