IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_case_management_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_case_management_key (
            d_case_management_key bigint IDENTITY(1,1) NOT NULL,
            public_health_case_uid bigint NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE(),
            PRIMARY KEY (d_case_management_key)
        );
        declare @max bigint;
        select @max=max(D_CASE_MANAGEMENT_KEY)+1 from dbo.D_CASE_MANAGEMENT;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_case_management_key', RESEED, @max);

    END;
