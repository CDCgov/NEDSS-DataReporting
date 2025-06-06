IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_SMR_EXAM_TY_GROUP' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[D_SMR_EXAM_TY_GROUP](
		[D_SMR_EXAM_TY_GROUP_KEY] [bigint] NOT NULL,
	CONSTRAINT [PK_D_SMR_EXAM_TY_GROUP] PRIMARY KEY CLUSTERED 
	(
		[D_SMR_EXAM_TY_GROUP_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
END;

IF NOT EXISTS ( SELECT 1 FROM [dbo].D_SMR_EXAM_TY_GROUP WHERE D_SMR_EXAM_TY_GROUP_KEY = 1 )
BEGIN
	INSERT INTO [dbo].D_SMR_EXAM_TY_GROUP (D_SMR_EXAM_TY_GROUP_KEY) VALUES (1);
END;