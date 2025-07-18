IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_var_pam_key' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[nrt_var_pam_key](
		[D_VAR_PAM_KEY] [bigint] IDENTITY(1,1) NOT NULL,
		[VAR_PAM_UID] [bigint] NOT NULL,
	CONSTRAINT PK_D_VAR_PAM PRIMARY KEY  CLUSTERED 
		(
			D_VAR_PAM_KEY,
			VAR_PAM_UID
		)  ON [PRIMARY] 
    ) ON [PRIMARY];

        declare @max bigint;
        select @max=max(d_var_pam_key)+1 from dbo.D_VAR_PAM ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW
        DBCC CHECKIDENT ('dbo.nrt_var_pam_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_var_pam_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_var_pam_key'))
            BEGIN
                ALTER TABLE dbo.nrt_var_pam_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_var_pam_key'))
            BEGIN
                ALTER TABLE dbo.nrt_var_pam_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;
