-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
ALTER DATABASE NBS_SRTE SET COMPATIBILITY_LEVEL = 130;

-- Enable CDC for tables 
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Anatomic_site_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Anatomic_site_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'City_code_value' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'City_code_value',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Cntycity_code_value' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Cntycity_code_value',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Code_value_clinical' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Code_value_clinical',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Code_value_general' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Code_value_general',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Codeset' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Codeset',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Codeset_Group_Metadata' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Codeset_Group_Metadata',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Condition_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Condition_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Country_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Country_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Country_Code_ISO' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Country_Code_ISO',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Country_XREF' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Country_XREF',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'ELR_XREF' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'ELR_XREF',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'IMRDBMapping' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'IMRDBMapping',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Investigation_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Investigation_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Jurisdiction_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Jurisdiction_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Jurisdiction_participation' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Jurisdiction_participation',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Lab_coding_system' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Lab_coding_system',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Lab_result' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Lab_result',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Lab_result_Snomed' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Lab_result_Snomed',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Lab_test' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Lab_test',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Labtest_loinc' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Labtest_loinc',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Labtest_Progarea_Mapping' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Labtest_Progarea_Mapping',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Language_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Language_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'LDF_page_set' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'LDF_page_set',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'LOINC_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'LOINC_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Loinc_condition' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Loinc_condition',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Loinc_snomed_condition' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Loinc_snomed_condition',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NAICS_Industry_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NAICS_Industry_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Occupation_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Occupation_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Participation_type' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Participation_type',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Program_area_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Program_area_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Race_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Race_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Snomed_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Snomed_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Specimen_source_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Specimen_source_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Standard_XREF' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Standard_XREF',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'State_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'State_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'State_county_code_value' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'State_county_code_value',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'State_model' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'State_model',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'TotalIDM' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'TotalIDM',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Treatment_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Treatment_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Unit_code' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Unit_code',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Zip_code_value' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Zip_code_value',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Zipcnty_code_value' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Zipcnty_code_value',@role_name = NULL;
    END;
