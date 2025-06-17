IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_date' and xtype = 'U')
CREATE TABLE dbo.nrt_observation_date (
    observation_uid     bigint                                          NOT NULL,
    ovd_seq             smallint                                        NULL,
    ovd_from_date       datetime                                        NULL,
    ovd_to_date         datetime                                        NULL,
    batch_id            bigint                                          NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime),
    PRIMARY KEY (observation_uid)
);