IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_key' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation_key (
	d_investigation_key bigint IDENTITY(1,1) NOT NULL,
	case_uid bigint NULL
);

declare @max bigint;
select @max=max(INVESTIGATION_KEY)+1 from dbo.INVESTIGATION;
select @max;
if @max IS NULL   --check when max is returned as null
  SET @max = 1;
DBCC CHECKIDENT ('dbo.nrt_investigation_key', RESEED, @max);


IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_investigation_key'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_investigation_key'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;