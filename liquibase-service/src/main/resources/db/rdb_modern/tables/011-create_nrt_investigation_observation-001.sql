IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_observation' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation_observation (
    public_health_case_uid bigint                                          NULL,
    observation_id         bigint                                          NULL,
    refresh_datetime       datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime           datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_observation' and xtype = 'U')
    BEGIN

--CNDE-1902
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'root_type_cd' AND Object_ID = Object_ID(N'nrt_investigation_observation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation_observation ADD root_type_cd VARCHAR(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'branch_id' AND Object_ID = Object_ID(N'nrt_investigation_observation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation_observation ADD branch_id BIGINT;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'branch_type_cd' AND Object_ID = Object_ID(N'nrt_investigation_observation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation_observation ADD branch_type_cd VARCHAR(50);
            END;

    END;