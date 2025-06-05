-- table is not dropped and recreated, as D_INTERVIEW_KEY does not retain the key-uid relationship

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_key' and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_interview_key (
            d_interview_key bigint IDENTITY (1,1) NOT NULL,
            interview_uid   bigint                NULL
        );
        declare @max bigint;
        select @max=max(d_interview_key)+1 from dbo.D_INTERVIEW ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW
        DBCC CHECKIDENT ('dbo.nrt_interview_key', RESEED, @max);

    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_interview_key'))
            BEGIN
                ALTER TABLE dbo.nrt_interview_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_interview_key'))
            BEGIN
                ALTER TABLE dbo.nrt_interview_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;
