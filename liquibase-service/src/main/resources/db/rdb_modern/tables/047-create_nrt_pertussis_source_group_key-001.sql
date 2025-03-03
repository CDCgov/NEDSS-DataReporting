IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_source_group_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_pertussis_source_group_key (
            PERTUSSIS_SUSPECT_SRC_GRP_KEY bigint IDENTITY(1,1) NOT NULL,
            public_health_case_uid bigint NULL
        );
        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(PERTUSSIS_SUSPECT_SRC_GRP_KEY) + 1, 2) FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP);
        DBCC CHECKIDENT('dbo.nrt_pertussis_source_group_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP)
    BEGIN

        INSERT INTO dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP (PERTUSSIS_SUSPECT_SRC_GRP_KEY)
        SELECT 1;

    END;