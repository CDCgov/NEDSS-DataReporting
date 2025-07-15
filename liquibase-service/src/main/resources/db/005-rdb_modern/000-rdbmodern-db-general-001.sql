-- Query update to run against RDB with RDB_modern compatibility
-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
DECLARE @CURRENT_DB NVARCHAR(128) = db_name()
IF (SELECT COMPATIBILITY_LEVEL FROM sys.databases WHERE name =  @CURRENT_DB)<150
    BEGIN
        EXEC('ALTER DATABASE '+@CURRENT_DB+' SET COMPATIBILITY_LEVEL = 150');
        PRINT 'Updated ' + @CURRENT_DB + ' to compatibility level 150.'
    END