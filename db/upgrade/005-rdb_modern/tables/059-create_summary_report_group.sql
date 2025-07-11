--CNDE-2292
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'SUMMARY_CASE_GROUP'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.SUMMARY_CASE_GROUP
        (
            SUMMARY_CASE_SRC_KEY bigint       NOT NULL PRIMARY KEY,
            SUMMARY_CASE_SRC_TXT varchar(100) NULL
        )
    END;