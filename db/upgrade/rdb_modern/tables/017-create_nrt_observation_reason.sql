IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_reason' and xtype = 'U')
CREATE TABLE rdb_modern.dbo.nrt_observation_reason(
    observation_uid     bigint                                          NOT NULL,
    reason_cd           varchar(20)                                     NULL,
    reason_desc_txt     varchar(100)                                    NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);
