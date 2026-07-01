-- Query update to run against RDB with RDB_modern compatibility
-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
DECLARE @CURRENT_DB NVARCHAR(128) = db_name()
IF
    (
        SELECT COMPATIBILITY_LEVEL FROM SYS.DATABASES
        WHERE NAME = @CURRENT_DB
    ) < 130
    BEGIN
        EXEC (
            'ALTER DATABASE ' + @CURRENT_DB + ' SET COMPATIBILITY_LEVEL = 130'
        );
        PRINT 'Updated ' + @CURRENT_DB + ' to compatibility level 130.'
    END
