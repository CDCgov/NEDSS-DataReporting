-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
ALTER DATABASE NBS_ODSE SET COMPATIBILITY_LEVEL = 130;

-- Check if Treatment table exists and CDC is not enabled, then enable CDC
if not exists(
    SELECT 1
    FROM sys.tables
    WHERE name = 'Treatment' and is_tracked_by_cdc = 1)
    begin
        exec sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Treatment',@role_name = NULL;
    end;

-- CNDE-2340
IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Page_cond_mapping')
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Page_cond_mapping',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_page')
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_page',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_ui_metadata')
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_ui_metadata',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'NBS_rdb_metadata')
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'NBS_rdb_metadata',@role_name = NULL;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = 'State_Defined_Field_Metadata' AND is_tracked_by_cdc = 1)
    BEGIN
        EXEC sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'State_Defined_Field_Metadata',@role_name = NULL;
    END;