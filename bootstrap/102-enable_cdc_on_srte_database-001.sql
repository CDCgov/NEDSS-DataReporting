-- ------------------------------------------
-- 1. Enable CDC at Database Level
-- ------------------------------------------
IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_SRTE') = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.databases WHERE NAME = 'rdsadmin') -- for aws
    BEGIN
        PRINT 'AWS RDS detected. Enabling CDC for NBS_SRTE using rds_cdc_enable_db';
        EXEC msdb.dbo.rds_cdc_enable_db 'NBS_SRTE';
    END
    ELSE
    BEGIN
        PRINT 'Standard SQL Server detected. Enabling CDC for NBS_SRTE using sp_cdc_enable_db';
        EXEC('USE [NBS_SRTE]; EXEC sys.sp_cdc_enable_db;');
    END
END
ELSE
BEGIN
    PRINT 'CDC is already enabled for NBS_SRTE';
END
GO

-- ------------------------------------------
-- 2. Enable CDC for Tables
-- ------------------------------------------
USE [NBS_SRTE];
GO

DECLARE @tablesToEnable TABLE (TableName NVARCHAR(128));

INSERT INTO @tablesToEnable (TableName)
SELECT TableName
FROM (VALUES 
    ('Anatomic_site_code'),
    ('City_code_value'),
    ('Cntycity_code_value'),
    ('Code_value_clinical'),
    ('Code_value_general'),
    ('Codeset'),
    ('Codeset_Group_Metadata'),
    ('Condition_code'),
    ('Country_code'),
    ('Country_Code_ISO'),
    ('Country_XREF'),
    ('ELR_XREF'),
    ('IMRDBMapping'),
    ('Investigation_code'),
    ('Jurisdiction_code'),
    ('Jurisdiction_participation'),
    ('Lab_coding_system'),
    ('Lab_result'),
    ('Lab_result_Snomed'),
    ('Lab_test'),
    ('Labtest_loinc'),
    ('Labtest_Progarea_Mapping'),
    ('Language_code'),
    ('LDF_page_set'),
    ('LOINC_code'),
    ('Loinc_condition'),
    ('Loinc_snomed_condition'),
    ('NAICS_Industry_code'),
    ('Occupation_code'),
    ('Participation_type'),
    ('Program_area_code'),
    ('Race_code'),
    ('Snomed_code'),
    ('Specimen_source_code'),
    ('Standard_XREF'),
    ('State_code'),
    ('State_county_code_value'),
    ('State_model'),
    ('TotalIDM'),
    ('Treatment_code'),
    ('Unit_code'),
    ('Zip_code_value'),
    ('Zipcnty_code_value')
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
