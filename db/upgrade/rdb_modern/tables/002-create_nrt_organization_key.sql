IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_organization_key (
            d_organization_key bigint IDENTITY (1,1) NOT NULL,
            organization_uid   bigint                NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE(),
            PRIMARY KEY (d_organization_key)
        );

        declare @max bigint;
        select @max=max(organization_key)+1 from dbo.D_ORGANIZATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_organization_key', RESEED, @max);
    END