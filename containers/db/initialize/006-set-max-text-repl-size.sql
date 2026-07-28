-- ==========================================
-- Dev/CI CDC bootstrap verification baseline
-- Ensures bootstrap script 101 must raise the 64 KiB default.
-- ==========================================

USE [master];
GO

DECLARE @showAdvancedOptionsWasEnabled BIT;

SELECT @showAdvancedOptionsWasEnabled = CONVERT(BIT, VALUE_IN_USE)
FROM SYS.CONFIGURATIONS
WHERE NAME = 'show advanced options';

IF @showAdvancedOptionsWasEnabled = 0
    BEGIN
        EXEC SYS.SP_CONFIGURE 'show advanced options', 1;
        RECONFIGURE;
    END

EXEC SYS.SP_CONFIGURE 'max text repl size (B)', 65536;
RECONFIGURE;

IF (
    SELECT CONVERT(INT, VALUE_IN_USE)
    FROM SYS.CONFIGURATIONS
    WHERE NAME = 'max text repl size (B)'
) <> 65536
    BEGIN
        THROW 50000, 'Could not set max text repl size (B) to 65536.', 1;
    END

IF @showAdvancedOptionsWasEnabled = 0
    BEGIN
        EXEC SYS.SP_CONFIGURE 'show advanced options', 0;
        RECONFIGURE;
    END
GO
