---------------------------------------------------------------------------------------------------
--  Enable CDC for NBS_ODSE 
---------------------------------------------------------------------------------------------------
USE NBS_ODSE;

-- TODO Enable CLR (Might not be necessary)
-- EXEC sp_configure 'clr enabled', 1; RECONFIGURE;

-- TODO Set sa as db_owner of NBS_ODSE and? enable cdc
EXEC sp_changedbowner 'sa';
-- Enable at database level
IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_ODSE') = 0
BEGIN
    PRINT 'Enabling CDC for NBS_ODSE';
    EXEC sys.sp_cdc_enable_db;
END

-- Enable for tables
DECLARE @tableName NVARCHAR(128);
DECLARE @enableCDCSQL NVARCHAR(MAX);

DECLARE @tablesToEnable TABLE (
    TableName NVARCHAR(128)
);

INSERT INTO @tablesToEnable (TableName) VALUES
    ('Person'),
    ('Organization'),
    ('Observation'),
    ('Public_health_case'),
    ('Treatment'),
    ('state_defined_field_data'),
    ('Notification'),
    ('Interview'),
    ('Place'),
    ('CT_contact'),
    ('Auth_user'),
    ('Intervention'),
    ('Act_relationship')
;

DECLARE cur CURSOR FOR SELECT TableName FROM @tablesToEnable;
OPEN cur;
FETCH NEXT FROM cur INTO @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF (SELECT is_tracked_by_cdc FROM sys.tables WHERE name = @tableName) = 0
    BEGIN
        PRINT 'Enabling CDC for table ' + @tableName;
        EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = @tableName, @role_name = NULL;
    END

    FETCH NEXT FROM cur INTO @tableName;
END

CLOSE cur;
DEALLOCATE cur;
