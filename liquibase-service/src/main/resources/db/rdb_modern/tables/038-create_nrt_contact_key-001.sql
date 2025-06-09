IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_contact_key' and xtype = 'U')
BEGIN
    CREATE TABLE dbo.nrt_contact_key (
       d_contact_record_key bigint IDENTITY (1,1) NOT NULL,
       contact_uid   bigint                NULL
    );
    declare @max bigint;
    select @max=max(d_contact_record_key)+1 from dbo.D_CONTACT_RECORD ;
    select @max;
    if @max IS NULL
        SET @max = 2;
    DBCC CHECKIDENT ('dbo.nrt_contact_key', RESEED, @max);
END

IF NOT EXISTS (SELECT 1 FROM dbo.D_CONTACT_RECORD)
BEGIN
    INSERT INTO dbo.D_CONTACT_RECORD (d_contact_record_key)
    SELECT 1;
END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_contact_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_contact_key'))
            BEGIN
                ALTER TABLE dbo.nrt_contact_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_contact_key'))
            BEGIN
                ALTER TABLE dbo.nrt_contact_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;
