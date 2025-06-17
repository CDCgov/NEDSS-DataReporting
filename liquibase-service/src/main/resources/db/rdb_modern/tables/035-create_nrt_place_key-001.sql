IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_place_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_place_key
        (
            d_place_key       bigint IDENTITY (1,1) NOT NULL,
            place_uid         bigint                NULL,
            place_locator_uid varchar(30)           NULL,
        );
        declare @max bigint;
        select @max = max(place_key) + 1 from dbo.D_PLACE;
        select @max;
        if @max IS NULL --check when max is returned as null
            SET @max = 2; --Start from key=2
        DBCC CHECKIDENT ('dbo.nrt_place_key', RESEED, @max);

    END


IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_place_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_place_key'))
            BEGIN
                ALTER TABLE dbo.nrt_place_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_place_key'))
            BEGIN
                ALTER TABLE dbo.nrt_place_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_place_key'))
    BEGIN
        ALTER TABLE dbo.nrt_place_key
        ADD CONSTRAINT pk_d_place_key_pk PRIMARY KEY (d_place_key);
    END;