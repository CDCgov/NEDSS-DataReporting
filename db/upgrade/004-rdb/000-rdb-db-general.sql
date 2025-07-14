-- Upgrade compatibility level to allow inbuilt functions such as StringSplit
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = 'RDB' AND COMPATIBILITY_LEVEL = 130)
BEGIN
    ALTER DATABASE RDB SET COMPATIBILITY_LEVEL = 130;
END
