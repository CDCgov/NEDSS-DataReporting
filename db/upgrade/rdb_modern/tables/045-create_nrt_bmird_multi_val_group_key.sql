IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_bmird_multi_val_group_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_bmird_multi_val_group_key (
            BMIRD_MULTI_VAL_GRP_KEY bigint IDENTITY(1,1) NOT NULL,
            public_health_case_uid bigint NULL
        );
        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(BMIRD_MULTI_VAL_GRP_KEY) + 1, 2) FROM dbo.BMIRD_MULTI_VALUE_FIELD_GROUP);
        DBCC CHECKIDENT('dbo.nrt_bmird_multi_val_group_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.BMIRD_MULTI_VALUE_FIELD_GROUP)
    BEGIN

        INSERT INTO dbo.BMIRD_MULTI_VALUE_FIELD_GROUP (BMIRD_MULTI_VAL_GRP_KEY)
        SELECT 1;

    END;