IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_treatment_group_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_pertussis_treatment_group_key (
            PERTUSSIS_TREATMENT_GRP_KEY bigint IDENTITY(1,1) NOT NULL,
            public_health_case_uid bigint NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE()
        );
        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(PERTUSSIS_TREATMENT_GRP_KEY) + 1, 2) FROM dbo.PERTUSSIS_TREATMENT_GROUP);
        DBCC CHECKIDENT('dbo.nrt_pertussis_treatment_group_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.PERTUSSIS_TREATMENT_GROUP)
    BEGIN

        INSERT INTO dbo.PERTUSSIS_TREATMENT_GROUP (PERTUSSIS_TREATMENT_GRP_KEY)
        SELECT 1;

    END;
