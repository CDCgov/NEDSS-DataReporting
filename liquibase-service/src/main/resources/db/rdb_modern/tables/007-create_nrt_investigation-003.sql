IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigation_count' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation ADD investigation_count bigint;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'case_count' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation ADD case_count bigint;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigator_assigned_datetime' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation ADD investigator_assigned_datetime datetime;
            END;
    END;
