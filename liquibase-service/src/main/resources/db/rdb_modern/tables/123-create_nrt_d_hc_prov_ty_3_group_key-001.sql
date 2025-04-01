IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_hc_prov_ty_3_group_key' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[nrt_d_hc_prov_ty_3_group_key](
		[D_HC_PROV_TY_3_GROUP_KEY] [bigint] IDENTITY(2,1) NOT NULL,
		[TB_PAM_UID] [bigint] NOT NULL,
	CONSTRAINT [NRT_D_HC_PROV_TY_3_GROUP_KEY_PK] PRIMARY KEY CLUSTERED 
	(
		[D_HC_PROV_TY_3_GROUP_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY];
	DECLARE @max bigint = (SELECT ISNULL(MAX(D_HC_PROV_TY_3_GROUP_KEY)+1, 2) FROM dbo.D_HC_PROV_TY_3_GROUP);
	DBCC CHECKIDENT ('dbo.nrt_d_hc_prov_ty_3_group_key', RESEED, @max);	
END