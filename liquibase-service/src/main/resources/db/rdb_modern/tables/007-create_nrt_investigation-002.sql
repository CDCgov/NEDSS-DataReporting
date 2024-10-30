IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation' and xtype = 'U')
    BEGIN

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_local_id' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_local_id;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_add_time' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_add_time;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'notification_record_status_cd' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_record_status_cd;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'notification_last_chg_time' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation DROP COLUMN notification_last_chg_time;
            END;

    END;
