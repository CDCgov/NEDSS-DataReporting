IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_case_management_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_case_management_key (
            d_case_management_key bigint IDENTITY(1,1) NOT NULL,
            public_health_case_uid bigint NULL
        );
        declare @max bigint;
        select @max=max(D_CASE_MANAGEMENT_KEY)+1 from dbo.D_CASE_MANAGEMENT;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_case_management_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_case_management_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_case_management_key'))
            BEGIN
                ALTER TABLE dbo.nrt_case_management_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_case_management_key'))
            BEGIN
                ALTER TABLE dbo.nrt_case_management_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_case_management_key'))
    BEGIN
        ALTER TABLE dbo.nrt_case_management_key
        ADD CONSTRAINT nrt_case_management_key_pk PRIMARY KEY (d_case_management_key);
    END