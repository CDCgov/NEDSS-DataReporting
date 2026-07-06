IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_metadata_columns' and xtype = 'U')
CREATE TABLE dbo.nrt_metadata_columns
(
    TABLE_NAME       varchar(100)                                    NOT NULL,
    RDB_COLUMN_NM    varchar(30)                                     NOT NULL,
    NEW_FLAG         bit                                             NULL,
    LAST_CHG_TIME    datetime                                        NULL,
    LAST_CHG_USER_ID bigint                                          NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

--removing column as it is no more needed
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_metadata_columns' and xtype = 'U')
BEGIN
        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'new_flag' AND Object_ID = Object_ID(N'nrt_metadata_columns'))
        BEGIN
            ALTER TABLE dbo.nrt_metadata_columns DROP COLUMN new_flag;
        END;
END;
