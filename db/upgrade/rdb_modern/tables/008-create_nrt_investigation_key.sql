IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_investigation_key (
            d_investigation_key bigint IDENTITY(1,1) NOT NULL,
            case_uid bigint NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE(),
            PRIMARY KEY (d_investigation_key)
        );
        declare @max bigint;
        select @max=max(INVESTIGATION_KEY)+1 from dbo.INVESTIGATION;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_investigation_key', RESEED, @max);
    END;
