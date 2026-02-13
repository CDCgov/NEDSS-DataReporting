-- 1. DEBEZIUM SERVICE PERMISSIONS
DECLARE @DebeziumServiceName NVARCHAR(100) = 'debezium_service';
DECLARE @DebeziumUserName NVARCHAR(150) = @DebeziumServiceName + '_rdb';


-- ==========================================
-- PERMISSION GRANTS
-- ==========================================

-- DEBEZIUM SERVICE PERMISSIONS

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @DebeziumUserName)
    BEGIN
        DECLARE @AddRoleMemberDebeziumODSESQL NVARCHAR(MAX) = 'EXEC sp_addrolemember ''db_datareader'', ''' + @DebeziumUserName + '''';
        EXEC sp_executesql @AddRoleMemberDebeziumODSESQL;
        PRINT 'Added [' + @DebeziumUserName + '] to db_datareader role in ' +@ODSE_DB;
    END
PRINT 'Debezium service user permission grants completed.';