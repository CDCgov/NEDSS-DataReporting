IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_out_of_cntry_key' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[nrt_d_out_of_cntry_key](
        [D_OUT_OF_CNTRY_KEY] [bigint] IDENTITY (2,1) NOT NULL,
        [NBS_CASE_ANSWER_UID] [bigint] NOT NULL,
        [TB_PAM_UID] [bigint] NOT NULL
    CONSTRAINT [NRT_D_OUT_OF_CNTRY_KEY_PK] PRIMARY KEY CLUSTERED 
	(
		[D_OUT_OF_CNTRY_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY];
    declare @max bigint;
	select @max=MAX(D_OUT_OF_CNTRY_KEY) + 1 FROM [dbo].[D_OUT_OF_CNTRY] WITH (NOLOCK);
	select @max;
	if @max IS NULL --check when max is returned as null
		set @max = 2
		DBCC CHECKIDENT ('dbo.nrt_d_out_of_cntry_key', RESEED, @max);
END
