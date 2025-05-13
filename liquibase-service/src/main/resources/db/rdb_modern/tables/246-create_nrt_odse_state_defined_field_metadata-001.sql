IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_state_defined_field_metadata' and xtype = 'U')
   BEGIN
    CREATE TABLE [dbo].[nrt_odse_state_defined_field_metadata](
        [ldf_uid] [bigint] NOT NULL,
        [active_ind] [char](1) NULL,
        [add_time] [datetime] NOT NULL,
        [admin_comment] [varchar](300) NULL,
        [business_object_nm] [varchar](50) NULL,
        [category_type] [varchar](50) NULL,
        [cdc_national_id] [varchar](50) NULL,
        [class_cd] [varchar](20) NULL,
        [code_set_nm] [varchar](256) NULL,
        [condition_cd] [varchar](10) NULL,
        [condition_desc_txt] [varchar](100) NULL,
        [data_type] [varchar](50) NULL,
        [deployment_cd] [varchar](10) NULL,
        [display_order_nbr] [int] NULL,
        [field_size] [varchar](10) NULL,
        [label_txt] [varchar](300) NULL,
        [ldf_page_id] [varchar](50) NULL,
        [required_ind] [char](1) NULL,
        [state_cd] [varchar](10) NULL,
        [validation_txt] [varchar](50) NULL,
        [validation_jscript_txt] [varchar](3000) NULL,
        [record_status_time] [datetime] NOT NULL,
        [record_status_cd] [varchar](20) NOT NULL,
        [custom_subform_metadata_uid] [bigint] NULL,
        [html_tag] [varchar](50) NULL,
        [import_version_nbr] [bigint] NULL,
        [nnd_ind] [char](1) NULL,
        [ldf_oid] [varchar](50) NULL,
        [version_ctrl_nbr] [smallint] NULL,
        [NBS_QUESTION_UID] [bigint] NULL,
        CONSTRAINT [PK_state_defined_field] PRIMARY KEY CLUSTERED 
        (
            [ldf_uid] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY]
        
   END;
