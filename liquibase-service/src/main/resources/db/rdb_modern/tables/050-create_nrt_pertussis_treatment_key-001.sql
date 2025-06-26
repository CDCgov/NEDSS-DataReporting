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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_treatment_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_pertussis_treatment_key'))
            BEGIN
                ALTER TABLE dbo.nrt_pertussis_treatment_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_pertussis_treatment_key'))
            BEGIN
                ALTER TABLE dbo.nrt_pertussis_treatment_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_pertussis_treatment_key'))
    BEGIN
        ALTER TABLE dbo.nrt_pertussis_treatment_key
        ADD CONSTRAINT pk_nrt_pertussis_treatment_key PRIMARY KEY (PERTUSSIS_TREATMENT_FLD_KEY);
    END;