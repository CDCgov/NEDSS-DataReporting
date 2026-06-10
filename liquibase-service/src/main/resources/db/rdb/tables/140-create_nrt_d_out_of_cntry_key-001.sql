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
	DECLARE @max bigint = (SELECT ISNULL(MAX(D_OUT_OF_CNTRY_KEY)+1, 2) FROM dbo.D_OUT_OF_CNTRY);
	DBCC CHECKIDENT ('dbo.nrt_d_out_of_cntry_key', RESEED, @max);	
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_out_of_cntry_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_d_out_of_cntry_key'))
            BEGIN
                ALTER TABLE dbo.nrt_d_out_of_cntry_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_d_out_of_cntry_key'))
            BEGIN
                ALTER TABLE dbo.nrt_d_out_of_cntry_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;