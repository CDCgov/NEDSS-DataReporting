IF (SELECT is_cdc_enabled FROM sys.databases WHERE name = 'NBS_ODSE') = 1
BEGIN
    PRINT 'CDC is already enabled for NBS_ODSE';
END
ELSE
BEGIN
    IF EXISTS (SELECT 1 FROM sys.databases WHERE NAME = 'rdsadmin') -- for aws
    BEGIN
        PRINT 'AWS RDS detected. Enabling CDC for NBS_ODSE using rds_cdc_enable_db';
        EXEC msdb.dbo.rds_cdc_enable_db 'NBS_ODSE';
    END
    ELSE
    BEGIN
        PRINT 'Standard SQL Server detected. Enabling CDC for NBS_ODSE using sp_cdc_enable_db';
        -- Use dynamic SQL for USE to ensure context switch happens correctly within the block
        EXEC('USE [NBS_ODSE]; EXEC sys.sp_cdc_enable_db;');
    END
END
GO
