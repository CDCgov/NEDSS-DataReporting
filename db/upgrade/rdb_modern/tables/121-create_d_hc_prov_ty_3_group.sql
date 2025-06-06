IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_HC_PROV_TY_3_GROUP' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[D_HC_PROV_TY_3_GROUP](
		[D_HC_PROV_TY_3_GROUP_KEY] [bigint] NOT NULL,
	CONSTRAINT [PK_D_HC_PROV_TY_3_GROUP] PRIMARY KEY CLUSTERED 
	(
		[D_HC_PROV_TY_3_GROUP_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
END;

IF NOT EXISTS ( SELECT 1 FROM [dbo].D_HC_PROV_TY_3_GROUP WHERE D_HC_PROV_TY_3_GROUP_KEY = 1 )
BEGIN
	INSERT INTO [dbo].D_HC_PROV_TY_3_GROUP (D_HC_PROV_TY_3_GROUP_KEY) VALUES (1);
END;
