IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_observation' and xtype = 'U')
    BEGIN

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