-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
ALTER DATABASE NBS_SRTE SET COMPATIBILITY_LEVEL = 130;

-- Check if Treatment table exists and CDC is not enabled, then enable CDC
if not exists(
    SELECT 1
    FROM sys.tables
    WHERE name = 'Treatment' and is_tracked_by_cdc = 1)
    begin
        exec sys.sp_cdc_enable_table @source_schema = N'dbo',@source_name = N'Treatment',@role_name = NULL;
    end;