IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_txt' AND xtype = 'U')
CREATE TABLE dbo.nrt_observation_txt
(
    observation_uid  bigint                                          NOT NULL,
    ovt_seq          smallint                                        NOT NULL,
    ovt_txt_type_cd  varchar(20)                                     NULL,
    ovt_value_txt    varchar(2000)                                   NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_txt' AND xtype = 'U')
    BEGIN

--CNDE-2295
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'batch_id' AND Object_ID = Object_ID(N'nrt_observation_txt'))
            BEGIN
                ALTER TABLE dbo.nrt_observation_txt
                    ADD batch_id bigint;
            END;

    END;
