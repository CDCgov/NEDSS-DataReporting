IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_notifications' and xtype = 'U')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_notification' and xtype = 'U')
            BEGIN
                EXEC sys.sp_rename N'nrt_notifications', N'nrt_investigation_notification', 'OBJECT';
            END
    END
