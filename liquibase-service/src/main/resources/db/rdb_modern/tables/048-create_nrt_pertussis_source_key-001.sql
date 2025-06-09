IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_source_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_pertussis_source_key (
            PERTUSSIS_SUSPECT_SRC_FLD_KEY bigint IDENTITY(1,1) NOT NULL,
            PERTUSSIS_SUSPECT_SRC_GRP_KEY  bigint NOT NULL,
            public_health_case_uid bigint NULL,
            selection_number bigint NULL
        );
        --check for null and set default to 2
        DECLARE @max bigint = (SELECT ISNULL(MAX(PERTUSSIS_SUSPECT_SRC_FLD_KEY) + 1, 2) FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_FLD);
        DBCC CHECKIDENT('dbo.nrt_pertussis_source_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_FLD)
    BEGIN

        INSERT INTO dbo.PERTUSSIS_SUSPECTED_SOURCE_FLD (PERTUSSIS_SUSPECT_SRC_GRP_KEY, PERTUSSIS_SUSPECT_SRC_FLD_KEY)
        SELECT 1, 1;

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_source_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_pertussis_source_key'))
            BEGIN
                ALTER TABLE dbo.nrt_pertussis_source_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_pertussis_source_key'))
            BEGIN
                ALTER TABLE dbo.nrt_pertussis_source_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;