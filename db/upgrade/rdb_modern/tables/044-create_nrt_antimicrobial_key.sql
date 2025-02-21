IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_antimicrobial_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_antimicrobial_key (
            ANTIMICROBIAL_KEY bigint IDENTITY(1,1) NOT NULL,
            ANTIMICROBIAL_GRP_KEY  bigint NOT NULL,
            public_health_case_uid bigint NULL,
            selection_number bigint NULL
        );
        --check for null and set default to 2, as default record with key = 1 is not stored in ANTIMICROBIAL
        DECLARE @max bigint = (SELECT ISNULL(MAX(ANTIMICROBIAL_KEY) + 1, 2) FROM dbo.ANTIMICROBIAL);
        DBCC CHECKIDENT('dbo.nrt_antimicrobial_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1 FROM dbo.ANTIMICROBIAL)
    BEGIN

        INSERT INTO dbo.ANTIMICROBIAL (ANTIMICROBIAL_GRP_KEY, ANTIMICROBIAL_KEY)
        SELECT 1, 1;

    END;