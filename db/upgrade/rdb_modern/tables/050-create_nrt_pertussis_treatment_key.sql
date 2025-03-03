IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_treatment_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_pertussis_treatment_key (
            PERTUSSIS_TREATMENT_FLD_KEY bigint IDENTITY(1,1) NOT NULL,
            PERTUSSIS_TREATMENT_GRP_KEY  bigint NOT NULL,
            public_health_case_uid bigint NULL,
            selection_number bigint NULL
        );
        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(PERTUSSIS_TREATMENT_FLD_KEY) + 1, 2) FROM dbo.PERTUSSIS_TREATMENT_FIELD);
        DBCC CHECKIDENT('dbo.nrt_pertussis_treatment_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.PERTUSSIS_TREATMENT_FIELD)
    BEGIN

        INSERT INTO dbo.PERTUSSIS_TREATMENT_FIELD (PERTUSSIS_TREATMENT_GRP_KEY, PERTUSSIS_TREATMENT_FLD_KEY)
        SELECT 1, 1;

    END;