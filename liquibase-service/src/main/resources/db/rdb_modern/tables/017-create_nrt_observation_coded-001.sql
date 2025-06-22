IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_coded' and xtype = 'U')
CREATE TABLE dbo.nrt_observation_coded (
    observation_uid bigint NOT NULL,
    ovc_code varchar(20) NOT NULL,
    ovc_code_system_cd varchar(300) NULL,
    ovc_code_system_desc_txt varchar(100) NULL,
    ovc_display_name varchar(300) NULL,
    ovc_alt_cd varchar(50) NULL,
    ovc_alt_cd_desc_txt varchar(100) NULL,
    ovc_alt_cd_system_cd varchar(300) NULL,
    ovc_alt_cd_system_desc_txt varchar(100) NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    max_datetime datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_coded' and xtype = 'U')
    BEGIN

--CNDE-2295
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'batch_id' AND Object_ID = Object_ID(N'nrt_observation_coded'))
            BEGIN
                ALTER TABLE dbo.nrt_observation_coded
                ADD batch_id bigint;
            END;

    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_observation_coded'))
    BEGIN
        ALTER TABLE dbo.nrt_observation_coded
        ADD CONSTRAINT pk_nrt_observation_coded PRIMARY KEY (observation_uid,ovc_code);
    END;