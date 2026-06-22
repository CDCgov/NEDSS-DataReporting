-- ------------------------------------------
-- 1. Enable CDC at Database Level
-- ------------------------------------------
IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_ODSE') = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.databases WHERE NAME = 'rdsadmin') -- for aws
    BEGIN
        PRINT 'AWS RDS detected. Enabling CDC for NBS_ODSE using rds_cdc_enable_db';
        EXEC msdb.dbo.rds_cdc_enable_db 'NBS_ODSE';
    END
    ELSE
    BEGIN
        PRINT 'Standard SQL Server detected. Enabling CDC for NBS_ODSE using sp_cdc_enable_db';
        EXEC('USE [NBS_ODSE]; EXEC sys.sp_cdc_enable_db;');
    END
END
ELSE
BEGIN
    PRINT 'CDC is already enabled for NBS_ODSE';
END
GO

-- ------------------------------------------
-- 2. Enable CDC for Tables
-- ------------------------------------------
USE [NBS_ODSE];
GO

DECLARE @tablesToEnable TABLE (TableName NVARCHAR(128));

INSERT INTO @tablesToEnable (TableName)
SELECT TableName
FROM (VALUES 
    ('Act_relationship'),
    ('Auth_user'),
    ('CT_contact'),
    ('Intervention'),
    ('Interview'),
    ('NBS_page'),
    ('NBS_rdb_metadata'),
    ('NBS_ui_metadata'),
    ('Notification'),
    ('Observation'),
    ('Organization'),
    ('Page_cond_mapping'),
    ('Person'),
    ('Place'),
    ('Public_health_case'),
    ('state_defined_field_data'),
    ('State_Defined_Field_Metadata'),
    ('Treatment'),
    ('NBS_configuration'),
    ('LOOKUP_QUESTION')
) AS NewRows(TableName)
EXCEPT
SELECT name 
FROM sys.tables 
WHERE is_tracked_by_cdc = 1;

DECLARE @tableName NVARCHAR(128);
DECLARE cur CURSOR FOR SELECT TableName FROM @tablesToEnable;

OPEN cur;
FETCH NEXT FROM cur INTO @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Enabling CDC for table: ' + @tableName;
    BEGIN TRY
        EXEC sys.sp_cdc_enable_table 
            @source_schema = N'dbo', 
            @source_name = @tableName, 
            @role_name = NULL;
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Could not enable CDC for table ' + @tableName + '. Error: ' + ERROR_MESSAGE();
    END CATCH
    
    FETCH NEXT FROM cur INTO @tableName;
END

CLOSE cur;
DEALLOCATE cur;
GO
