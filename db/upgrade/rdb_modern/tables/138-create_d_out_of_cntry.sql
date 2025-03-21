IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_OUT_OF_CNTRY' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[D_OUT_OF_CNTRY](
		[TB_PAM_UID] [bigint] NOT NULL,
		[D_OUT_OF_CNTRY_KEY] [bigint] NOT NULL,
		[SEQ_NBR] [int] NULL,
		[D_OUT_OF_CNTRY_GROUP_KEY] [bigint] NOT NULL,
		[LAST_CHG_TIME] [datetime] NULL,
		[VALUE] [varchar](250) NULL,
	CONSTRAINT [PK_D_OUT_OF_CNTRY] PRIMARY KEY CLUSTERED 
	(
		[D_OUT_OF_CNTRY_KEY] ASC,
		[TB_PAM_UID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[D_OUT_OF_CNTRY]  WITH CHECK ADD  CONSTRAINT [FK_D_OUT_OF_CNTRY_D_OUT_OF_CNTRY_GROUP] FOREIGN KEY([D_OUT_OF_CNTRY_GROUP_KEY])
	REFERENCES [dbo].[D_OUT_OF_CNTRY_GROUP] ([D_OUT_OF_CNTRY_GROUP_KEY])

	ALTER TABLE [dbo].[D_OUT_OF_CNTRY] CHECK CONSTRAINT [FK_D_OUT_OF_CNTRY_D_OUT_OF_CNTRY_GROUP]
END