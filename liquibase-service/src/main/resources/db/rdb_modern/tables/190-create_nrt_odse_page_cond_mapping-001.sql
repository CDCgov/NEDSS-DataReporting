IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_Page_cond_mapping' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_odse_Page_cond_mapping] (
            [page_cond_mapping_uid] [bigint] NOT NULL,
            [wa_template_uid] [bigint] NOT NULL,
            [condition_cd] [varchar](20) NOT NULL,
            [add_time] [datetime] NOT NULL,
            [add_user_id] [bigint] NOT NULL,
            [last_chg_time] [datetime] NOT NULL,
            [last_chg_user_id] [bigint] NOT NULL,
            CONSTRAINT [PK_Page_cond_mapping] PRIMARY KEY CLUSTERED (
                [page_cond_mapping_uid] ASC
            ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY];

    END;