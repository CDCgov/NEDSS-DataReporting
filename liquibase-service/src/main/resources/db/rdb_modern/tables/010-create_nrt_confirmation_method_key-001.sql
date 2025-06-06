--CNDE-2378: Insert null confirmation_method_cd/desc
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_confirmation_method_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_confirmation_method_key
        (
            d_confirmation_method_key bigint IDENTITY (1,1) NOT NULL,
            confirmation_method_cd    varchar(50)           NULL
        );

        declare @max bigint;
        select @max = max(confirmation_method_key) + 1 from dbo.confirmation_method;
        select @max;
        if @max IS NULL --check when max is returned as null
            SET @max = 2;
        DBCC CHECKIDENT ('dbo.nrt_confirmation_method_key', RESEED, @max);
    END

IF NOT EXISTS (SELECT 1 FROM dbo.confirmation_method)
    BEGIN
        INSERT INTO dbo.confirmation_method (confirmation_method_key)
        SELECT 1;
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_confirmation_method_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_confirmation_method_key'))
            BEGIN
                ALTER TABLE dbo.nrt_confirmation_method_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_confirmation_method_key'))
            BEGIN
                ALTER TABLE dbo.nrt_confirmation_method_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;