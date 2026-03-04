---------------------------------------------------------------------------------------------------
--  Enable CDC for NBS_SRTE 
---------------------------------------------------------------------------------------------------
USE NBS_SRTE;

-- Enable at database level
IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_SRTE') = 0
BEGIN
    PRINT 'Enabling CDC for NBS_SRTE';
    EXEC sys.sp_cdc_enable_db;
END

-- Enable for tables
DECLARE @tableName NVARCHAR(128);
DECLARE @enableCDCSQL NVARCHAR(MAX);

DECLARE @tablesToEnable TABLE (
    TableName NVARCHAR(128)
);

INSERT INTO @tablesToEnable (TableName) VALUES
    ('Condition_code'),
    ('Program_area_code'),
    ('Language_code'),
    ('State_code'),
    ('Unit_code'),
    ('Cntycity_code_value'),
    ('Lab_result'),
    ('Country_code'),
    ('Labtest_loinc'),
    ('ELR_XREF'),
    ('Loinc_condition'),
    ('Loinc_snomed_condition'),
    ('Lab_test'),
    ('Zip_code_value'),
    ('Zipcnty_code_value'),
    ('Lab_result_Snomed'),
    ('Investigation_code'),
    ('TotalIDM'),
    ('IMRDBMapping'),
    ('Anatomic_site_code'),
    ('Jurisdiction_code'),
    ('Lab_coding_system'),
    ('City_code_value'),
    ('LDF_page_set'),
    ('LOINC_code'),
    ('NAICS_Industry_code'),
    ('Codeset_Group_Metadata'),
    ('Country_Code_ISO'),
    ('Occupation_code'),
    ('Country_XREF'),
    ('Standard_XREF'),
    ('Code_value_clinical'),
    ('Code_value_general'),
    ('Race_code'),
    ('Participation_type'),
    ('Specimen_source_code'),
    ('Snomed_code'),
    ('State_county_code_value'),
    ('State_model'),
    ('Codeset'),
    ('Jurisdiction_participation'),
    ('Labtest_Progarea_Mapping'),
    ('Treatment_code'),
    ('Snomed_condition');

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



