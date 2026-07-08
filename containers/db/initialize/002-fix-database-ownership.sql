-- ==========================================
-- Dev/CI bootstrap
-- Ensures [sa] can enable CDC and owns the restored databases.
-- ==========================================

USE [master];
GO

DECLARE @Databases TABLE (Name sysname PRIMARY KEY);

INSERT INTO @Databases (Name)
VALUES
('NBS_ODSE'),
('NBS_SRTE'),
('RDB'),
('RDB_MODERN'),
('NBS_MSGOUTE');

DECLARE @DBName sysname;
DECLARE Db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT Name
FROM @Databases
WHERE DB_ID(Name) IS NOT NULL;

OPEN Db_cursor;
FETCH NEXT FROM Db_cursor INTO @DBName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC (
                N'ALTER AUTHORIZATION ON DATABASE::[' + @DBName + N'] TO [sa];'
            );
            PRINT 'Set owner of database [' + @DBName + '] to [sa].';
        END TRY
        BEGIN CATCH
            PRINT 'WARNING: Could not set owner for ['
            + @DBName
            + ']. Error: '
            + ERROR_MESSAGE();
        END CATCH;

        FETCH NEXT FROM Db_cursor INTO @DBName;
    END

CLOSE Db_cursor;
DEALLOCATE Db_cursor;
GO
