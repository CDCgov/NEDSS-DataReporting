IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_NBS_page' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_odse_NBS_page] (
            [nbs_page_uid] [bigint] NOT NULL,
            [wa_template_uid] [bigint] NOT NULL,
            [form_cd] [varchar](50) NULL,
            [desc_txt] [varchar](2000) NULL,
            [jsp_payload] [image] NULL,
            [datamart_nm] [varchar](21) NULL,
            [local_id] [varchar](50) NULL,
            [bus_obj_type] [varchar](50) NOT NULL,
            [last_chg_user_id] [bigint] NOT NULL,
            [last_chg_time] [datetime] NOT NULL,
            [record_status_cd] [varchar](20) NOT NULL,
            [record_status_time] [datetime] NOT NULL,
            CONSTRAINT [PK_nrt_odse_NBS_page] PRIMARY KEY CLUSTERED (
                [nbs_page_uid] ASC
            )
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

   END;