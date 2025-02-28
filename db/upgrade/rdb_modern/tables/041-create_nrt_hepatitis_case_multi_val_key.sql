IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_hepatitis_case_multi_val_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_hepatitis_case_multi_val_key (
          HEP_MULTI_VAL_DATA_KEY bigint IDENTITY(1,1) NOT NULL,
          HEP_MULTI_VAL_GRP_KEY  bigint NOT NULL,
          public_health_case_uid bigint NULL,
          selection_number bigint NULL
        );

        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(HEP_MULTI_VAL_DATA_KEY) + 1, 2) FROM dbo.hep_multi_value_field);
        DBCC CHECKIDENT('dbo.nrt_hepatitis_case_multi_val_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.hep_multi_value_field)
    BEGIN

        INSERT INTO dbo.HEP_MULTI_VALUE_FIELD
        (
            HEP_MULTI_VAL_GRP_KEY,
            HEP_MULTI_VAL_DATA_KEY
        )
        SELECT 1,1;

    END;
