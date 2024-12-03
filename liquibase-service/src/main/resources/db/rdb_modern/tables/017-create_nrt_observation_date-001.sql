IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_date' and xtype = 'U')
CREATE TABLE rdb_modern.dbo.nrt_observation_date (
    observation_uid bigint NOT NULL,
    ovd_from_date datetime NULL,
    ovd_to_date datetime NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    max_datetime datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_date' and xtype = 'U')
BEGIN
    IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ovd_seq' AND Object_ID = Object_ID(N'nrt_observation_date'))
       BEGIN
            ALTER TABLE dbo.nrt_observation_date ADD ovd_seq smallint;
    END;
END;