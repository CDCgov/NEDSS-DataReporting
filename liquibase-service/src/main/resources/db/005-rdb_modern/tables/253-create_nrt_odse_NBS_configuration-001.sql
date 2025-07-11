IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_NBS_configuration' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_odse_NBS_configuration](
            [config_key] [varchar](200) NOT NULL,
            [config_value] [varchar](2000) NULL,
            [short_name] [varchar](80) NULL,
            [desc_txt] [varchar](2000) NULL,
            [default_value] [varchar](2000) NULL,
            [valid_values] [varchar](2000) NULL,
            [category] [varchar](50) NULL,
            [add_release] [varchar](50) NULL,
            [version_ctrl_nbr] [smallint] NOT NULL,
            [add_user_id] [bigint] NOT NULL,
            [add_time] [datetime] NOT NULL,
            [last_chg_user_id] [bigint] NOT NULL,
            [last_chg_time] [datetime] NOT NULL,
            [status_cd] [char](1) NOT NULL,
            [status_time] [datetime] NOT NULL,
            [admin_comment] [varchar](2000) NULL,
            [system_usage] [varchar](2000) NULL,
            [config_value_large] [varchar](max) NULL,
        CONSTRAINT [PK_NBS_CONFIGURATION] PRIMARY KEY CLUSTERED 
        (
            [config_key] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
        ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

   END;