IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_notification_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_notification_key (
            d_notification_key bigint IDENTITY (1,1) NOT NULL,
            notification_uid   bigint                NULL
        );
        declare @max bigint;
        select @max=max(notification_key)+1 from dbo.NOTIFICATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_notification_key', RESEED, @max);

    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_notification_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_notification_key'))
            BEGIN
                ALTER TABLE dbo.nrt_notification_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_notification_key'))
            BEGIN
                ALTER TABLE dbo.nrt_notification_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_notification_key'))
    BEGIN
        ALTER TABLE dbo.nrt_notification_key
        ADD CONSTRAINT pk_notification_key PRIMARY KEY (d_notification_key);
    END