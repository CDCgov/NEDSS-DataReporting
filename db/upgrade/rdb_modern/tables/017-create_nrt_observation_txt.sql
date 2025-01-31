IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_txt' and xtype = 'U')
CREATE TABLE dbo.nrt_observation_txt (
    observation_uid     bigint                                          NOT NULL,
    ovt_seq             smallint                                        NOT NULL,
    ovt_txt_type_cd     varchar(20)                                     NULL,
    ovt_value_txt       varchar(2000)                                   NULL,
    refresh_datetime    datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime        datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);