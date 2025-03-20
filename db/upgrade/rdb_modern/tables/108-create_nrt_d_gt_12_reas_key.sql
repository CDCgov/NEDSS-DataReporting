IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_gt_12_reas_key' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[nrt_d_gt_12_reas_key](
        [D_GT_12_REAS_KEY] [bigint] IDENTITY (2,1) NOT NULL,
        [NBS_CASE_ANSWER_UID] [bigint] NOT NULL,
        [TB_PAM_UID] [bigint] NOT NULL
    CONSTRAINT [nrt_d_gt_12_reas_key_pk] PRIMARY KEY CLUSTERED 
	(
		[D_GT_12_REAS_KEY] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY];
    DECLARE @max bigint = (SELECT ISNULL(MAX(D_GT_12_REAS_KEY)+1, 2) FROM dbo.D_GT_12_REAS);
	DBCC CHECKIDENT ('dbo.nrt_d_gt_12_reas_key', RESEED, @max);	
END
