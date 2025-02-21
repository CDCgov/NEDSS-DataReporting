IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_bmird_multi_val_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_bmird_multi_val_key (
            BMIRD_MULTI_VAL_FIELD_KEY bigint IDENTITY(1,1) NOT NULL,
            BMIRD_MULTI_VAL_GRP_KEY  bigint NOT NULL,
            public_health_case_uid bigint NULL,
            selection_number bigint NULL
        );
        --check for null and set default to 2, as default record with key = 1 is not stored in BMIRD_MULTI_VALUE_FIELD
        DECLARE @max bigint = (SELECT ISNULL(MAX(BMIRD_MULTI_VAL_FIELD_KEY) + 1, 2) FROM dbo.BMIRD_MULTI_VALUE_FIELD);
        DBCC CHECKIDENT('dbo.nrt_bmird_multi_val_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.BMIRD_MULTI_VALUE_FIELD)
    BEGIN

        INSERT INTO dbo.BMIRD_MULTI_VALUE_FIELD (BMIRD_MULTI_VAL_GRP_KEY, BMIRD_MULTI_VAL_FIELD_KEY)
        SELECT 1, 1;

    END;