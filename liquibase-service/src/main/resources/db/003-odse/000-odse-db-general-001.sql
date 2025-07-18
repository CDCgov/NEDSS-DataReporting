-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'NBS_ODSE' AND COMPATIBILITY_LEVEL < 150)
    BEGIN
        ALTER DATABASE NBS_ODSE SET COMPATIBILITY_LEVEL = 150;
    END
