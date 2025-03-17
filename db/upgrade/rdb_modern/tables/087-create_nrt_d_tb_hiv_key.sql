IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_tb_hiv_key' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[nrt_d_tb_hiv_key](
		[D_TB_HIV_KEY] [bigint] IDENTITY(1,1) NOT NULL,
		[TB_PAM_UID] [bigint] NULL,
	CONSTRAINT [nrt_d_tb_hiv_key_pk] PRIMARY KEY CLUSTERED 
	(
		[D_TB_HIV_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY];
	declare @max bigint;
	select @max=MAX(D_TB_HIV_KEY) + 1 FROM [dbo].[D_TB_HIV] WITH (NOLOCK);
	select @max;
	if @max IS NULL --check when max is returned as null
		set @max = 2
		DBCC CHECKIDENT ('dbo.nrt_d_tb_hiv_key', RESEED, @max);
END