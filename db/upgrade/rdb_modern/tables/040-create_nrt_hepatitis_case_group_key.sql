IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_hepatitis_case_group_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_hepatitis_case_group_key (
          HEP_MULTI_VAL_GRP_KEY bigint IDENTITY(1,1) NOT NULL,
          public_health_case_uid bigint NULL,
          created_dttm DATETIME2 DEFAULT GETDATE(),
          updated_dttm DATETIME2 DEFAULT GETDATE()
        );
        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(HEP_MULTI_VAL_GRP_KEY) + 1, 2) FROM dbo.hep_multi_value_field_group);
        DBCC CHECKIDENT('dbo.nrt_hepatitis_case_group_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.hep_multi_value_field_group)
    BEGIN

        INSERT INTO dbo.HEP_MULTI_VALUE_FIELD_GROUP
        (
            HEP_MULTI_VAL_GRP_KEY
        )
        SELECT 1;

    END;
