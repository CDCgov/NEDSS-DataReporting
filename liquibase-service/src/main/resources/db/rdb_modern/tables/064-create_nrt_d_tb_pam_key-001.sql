IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_tb_pam_key' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[nrt_d_tb_pam_key](
		[D_TB_PAM_KEY] [bigint] IDENTITY(1,1) NOT NULL,
		[TB_PAM_UID] [bigint] NOT NULL,
	CONSTRAINT [nrt_d_tb_pam_key_pk] PRIMARY KEY CLUSTERED 
	(
		[D_TB_PAM_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY];
	declare @max bigint;
	select @max=MAX(D_TB_PAM_KEY) + 1 FROM [dbo].[D_TB_PAM] WITH (NOLOCK);
	select @max;
	if @max IS NULL --check when max is returned as null
		set @max = 2
		DBCC CHECKIDENT ('dbo.nrt_d_tb_pam_key', RESEED, @max);
END

