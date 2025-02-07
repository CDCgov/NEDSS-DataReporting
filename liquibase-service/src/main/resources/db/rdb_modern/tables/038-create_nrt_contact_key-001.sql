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
        SET @max = 1;
    DBCC CHECKIDENT ('dbo.nrt_contact_key', RESEED, @max);
END
