IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_coded' and xtype = 'U')
CREATE TABLE rdb_modern.dbo.nrt_observation_coded (
    observation_uid             bigint                                          NOT NULL,
    ovc_code                    varchar(20)                                     NOT NULL,
    ovc_code_system_cd          varchar(300)                                    NULL,
    ovc_code_system_desc_txt    varchar(100)                                    NULL,
    ovc_display_name            varchar(300)                                    NULL,
    ovc_alt_cd                  varchar(50)                                     NULL,
    ovc_alt_cd_desc_txt         varchar(100)                                    NULL,
    ovc_alt_cd_system_cd        varchar(300)                                    NULL,
    ovc_alt_cd_system_desc_txt  varchar(100)                                    NULL,
    refresh_datetime            datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);
