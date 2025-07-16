-- Enable CDC for tables
USE NBS_ODSE;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Act_relationship' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Act_relationship',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Auth_user' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Auth_user',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'CT_contact' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'CT_contact',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Intervention' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Intervention',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Interview' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Interview',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_page' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_page',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_rdb_metadata' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_rdb_metadata',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_ui_metadata' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_ui_metadata',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Notification' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Notification',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Observation' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Observation',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Organization' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Organization',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Page_cond_mapping' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Page_cond_mapping',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Person' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Person',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Place' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Place',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Public_health_case' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Public_health_case',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'state_defined_field_data' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'state_defined_field_data',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'State_Defined_Field_Metadata' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'State_Defined_Field_Metadata',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Treatment' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Treatment',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_configuration' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_configuration',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'LOOKUP_QUESTION' and is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'LOOKUP_QUESTION',@role_name = NULL;
    END;