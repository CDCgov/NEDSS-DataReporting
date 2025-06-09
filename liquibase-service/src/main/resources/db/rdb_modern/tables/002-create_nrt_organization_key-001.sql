IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_organization_key (
            d_organization_key bigint IDENTITY (1,1) NOT NULL,
            organization_uid   bigint                NULL
        );

        declare @max bigint;
        select @max=max(organization_key)+1 from dbo.D_ORGANIZATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_organization_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_organization_key'))
            BEGIN
                ALTER TABLE dbo.nrt_organization_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_organization_key'))
            BEGIN
                ALTER TABLE dbo.nrt_organization_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;