IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_group_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_ldf_group_key (
            d_ldf_group_key bigint IDENTITY(1,1) NOT NULL,
            business_object_uid bigint NULL
        );

        declare @max bigint;
        select @max=max(ldf_group_key)+1 from dbo.ldf_group;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2;
        DBCC CHECKIDENT ('dbo.nrt_ldf_group_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_group_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_ldf_group_key'))
            BEGIN
                ALTER TABLE dbo.nrt_ldf_group_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_ldf_group_key'))
            BEGIN
                ALTER TABLE dbo.nrt_ldf_group_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_ldf_group_key'))
BEGIN
    ALTER TABLE dbo.nrt_ldf_group_key
    ADD CONSTRAINT pk_ldf_group_key PRIMARY KEY (d_ldf_group_key);
END;