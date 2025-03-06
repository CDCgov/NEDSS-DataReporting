IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_treatment_key (
                                               d_treatment_key bigint IDENTITY (1,1) NOT NULL,
                                               treatment_uid   bigint                NULL
        );

        DECLARE @max bigint;
        SELECT @max = MAX(TREATMENT_KEY) + 1 FROM dbo.TREATMENT;

        IF @max IS NULL   --check when max is returned as null
            SET @max = 1;

        DBCC CHECKIDENT ('dbo.nrt_treatment_key', RESEED, @max);
    END