IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_interview_columns'
                 and xtype = 'U')
CREATE TABLE dbo.nrt_interview_columns
(
    TABLE_NAME       varchar(100),
    RDB_COLUMN_NM    varchar(30),
    NEW_FLAG         bit                                             NULL,
    LAST_CHG_TIME    datetime,
    LAST_CHG_USER_ID bigint,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

