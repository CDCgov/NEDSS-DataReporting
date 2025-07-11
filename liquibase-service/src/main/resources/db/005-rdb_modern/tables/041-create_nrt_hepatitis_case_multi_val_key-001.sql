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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_hepatitis_case_multi_val_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_hepatitis_case_multi_val_key'))
            BEGIN
                ALTER TABLE dbo.nrt_hepatitis_case_multi_val_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_hepatitis_case_multi_val_key'))
            BEGIN
                ALTER TABLE dbo.nrt_hepatitis_case_multi_val_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_hepatitis_case_multi_val_key'))
    BEGIN
        ALTER TABLE dbo.nrt_hepatitis_case_multi_val_key
        ADD CONSTRAINT pk_nrt_hepatitis_case_multi_val_key PRIMARY KEY (HEP_MULTI_VAL_DATA_KEY);
    END
