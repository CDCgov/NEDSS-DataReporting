-- table is not dropped and recreated, as d_vaccination_key does not retain the key-uid relationship
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_vaccination_key (
            d_vaccination_key bigint IDENTITY (1,1) NOT NULL,
            vaccination_uid   bigint                NULL
        );
        declare @max bigint;
        select @max=max(d_vaccination_key)+1 from dbo.D_VACCINATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW
        DBCC CHECKIDENT ('dbo.nrt_vaccination_key', RESEED, @max);
    END

IF NOT EXISTS (SELECT 1 FROM dbo.D_VACCINATION)
    BEGIN
        INSERT INTO dbo.D_VACCINATION (d_vaccination_key)
        SELECT 1;
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_vaccination_key'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_vaccination_key'))
            BEGIN
                ALTER TABLE dbo.nrt_vaccination_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND parent_object_id = OBJECT_ID('dbo.nrt_vaccination_key'))
BEGIN
    ALTER TABLE dbo.nrt_vaccination_key
    ADD CONSTRAINT pk_nrt_vaccination_key PRIMARY KEY (d_vaccination_key);
END;