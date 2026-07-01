-- Query update to run against RDB with RDB_modern compatibility
-- Upgrade compatibility level to allow inbuilt functions such as STRING_SPLIT and STRING_AGG
-- COMPATIBILITY_LEVEL 130 = SQL Server 2016
-- COMPATIBILITY_LEVEL 140 = SQL Server 2017
-- COMPATIBILITY_LEVEL 150 = SQL Server 2019
-- COMPATIBILITY_LEVEL 160 = SQL Server 2022
DECLARE @CURRENT_DB NVARCHAR(128) = db_name()
IF
    (
        SELECT COMPATIBILITY_LEVEL FROM SYS.DATABASES
        WHERE NAME = @CURRENT_DB
    ) < 150
    BEGIN
        EXEC (
            'ALTER DATABASE ' + @CURRENT_DB + ' SET COMPATIBILITY_LEVEL = 150'
        );
        PRINT 'Updated ' + @CURRENT_DB + ' to compatibility level 150.'
    END
