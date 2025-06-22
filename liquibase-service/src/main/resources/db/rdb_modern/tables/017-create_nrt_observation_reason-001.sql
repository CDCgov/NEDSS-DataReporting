IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_reason' and xtype = 'U')
CREATE TABLE dbo.nrt_observation_reason
(
    observation_uid  bigint NOT NULL,
    reason_cd        varchar(20) NULL,
    reason_desc_txt  varchar(100) NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_reason' AND xtype = 'U')
    BEGIN

--CNDE-2295
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'batch_id' AND Object_ID = Object_ID(N'nrt_observation_reason'))
            BEGIN
                ALTER TABLE dbo.nrt_observation_reason
                    ADD batch_id bigint;
            END;

    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_observation_reason'))
    BEGIN
        ALTER TABLE dbo.nrt_observation_reason
        ADD CONSTRAINT pk_nrt_observation_reason PRIMARY KEY (observation_uid);
    END
