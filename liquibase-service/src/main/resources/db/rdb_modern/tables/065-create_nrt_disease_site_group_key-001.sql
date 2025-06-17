IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_disease_site_group_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_disease_site_group_key
        (
            D_DISEASE_SITE_GROUP_KEY bigint IDENTITY (2,1) NOT NULL,
            TB_PAM_UID               bigint                NOT NULL

        );

        declare
            @max bigint;
        select @max = max(D_DISEASE_SITE_GROUP_KEY) + 1
        from dbo.d_disease_site_group;
        select @max;
        if
            @max IS NULL --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC
            CHECKIDENT ('dbo.nrt_disease_site_group_key', RESEED, @max);
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_disease_site_group_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_disease_site_group_key'))
            BEGIN
                ALTER TABLE dbo.nrt_disease_site_group_key
                ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_disease_site_group_key'))
            BEGIN
                ALTER TABLE dbo.nrt_disease_site_group_key
                ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_disease_site_group_key'))
    BEGIN
        ALTER TABLE dbo.nrt_disease_site_group_key
        ADD CONSTRAINT pk_nrt_disease_site_group_key PRIMARY KEY (D_DISEASE_SITE_GROUP_KEY, TB_PAM_UID);
    END;