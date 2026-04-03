-- Based on configuration, set @RDB_DB to either rdb_modern or rdb
DECLARE @RDB_DB NVARCHAR(128) = 'rdb';
IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
    BEGIN
        SET @RDB_DB = 'rdb_modern';
    END
PRINT 'Using database ' + @RDB_DB + ' in 023-load_nrt_data-001.sql';

-- Call the initialization procedure in the target database
DECLARE @Sql NVARCHAR(MAX) = 'EXEC ' + QUOTENAME(@RDB_DB) + '.dbo.sp_init_nrt_tables;';
EXEC sp_executesql @Sql;
GO
