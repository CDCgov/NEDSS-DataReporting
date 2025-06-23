-- ==========================================
-- DEBEZIUM SERVICE USER CREATION
-- ==========================================
DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';

-- Grant permissions on ODSE database (READ)
USE [NBS_ODSE];
PRINT 'Switched to database [NBS_ODSE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @CreateUserDebeziumODSESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
        EXEC sp_executesql @CreateUserDebeziumODSESQL;
        PRINT 'Created database user [' + @DebeziumUserName + '] in NBS_ODSE';
    END

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @DebeziumUserName + '] in NBS_ODSE...';
        DECLARE @AddRoleMemberDebeziumODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumODSESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in NBS_ODSE';
    END

-- Grant permissions on SRTE database (READ)
USE [NBS_SRTE];
PRINT 'Switched to database [NBS_SRTE]';

-- Check if user exists and create if not
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @CreateUserDebeziumSRTESQL NVARCHAR(MAX) = 'CREATE USER [' + @DebeziumUserName + '] FOR LOGIN [' + @DebeziumUserName + ']';
        EXEC sp_executesql @CreateUserDebeziumSRTESQL;
        PRINT 'Created database user [' + @DebeziumUserName + '] in NBS_SRTE';
    END

-- RE-GRANT PERMISSIONS (Execute every time)
IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        PRINT 'Re-granting permissions for [' + @DebeziumUserName + '] in NBS_SRTE...';
        DECLARE @AddRoleMemberDebeziumSRTESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumSRTESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in NBS_SRTE';
    END

PRINT 'Debezium service user permissions completed.';