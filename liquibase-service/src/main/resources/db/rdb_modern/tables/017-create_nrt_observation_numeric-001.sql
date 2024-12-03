IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_numeric' and xtype = 'U')
CREATE TABLE rdb_modern.dbo.nrt_observation_numeric (
    observation_uid bigint NOT NULL,
    ovn_high_range varchar(20) NULL,
    ovn_low_range varchar(20) NULL,
    ovn_comparator_cd_1 varchar(10) NULL,
    ovn_numeric_value_1 numeric(15,5) NULL,
    ovn_numeric_value_2 numeric(15,5) NULL,
    ovn_numeric_unit_cd varchar(20) NULL,
    ovn_separator_cd varchar(10) NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
    max_datetime datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation_numeric' and xtype = 'U')
BEGIN
     IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ovn_seq' AND Object_ID = Object_ID(N'nrt_observation_numeric'))
        BEGIN
            ALTER TABLE dbo.nrt_observation_numeric ADD ovn_seq smallint;
        END;
END;