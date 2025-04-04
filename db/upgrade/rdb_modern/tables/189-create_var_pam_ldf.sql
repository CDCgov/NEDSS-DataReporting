IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'var_pam_ldf' and xtype = 'U')  
BEGIN
    CREATE TABLE [dbo].[VAR_PAM_LDF](
	[INVESTIGATION_KEY] [numeric](20, 0) NULL,
	[VAR_PAM_UID] [numeric](20, 0) NULL,
	[add_time] [datetime2](3) NULL
	) ON [PRIMARY]
END


