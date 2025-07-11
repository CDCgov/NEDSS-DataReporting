IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_LDF_META_DATA' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[D_LDF_META_DATA](
	[ldf_uid] [bigint] NOT NULL,
	[active_ind] [char](1) NULL,
	[business_object_nm] [varchar](50) NULL,
	[cdc_national_id] [varchar](50) NULL,
	[class_cd] [varchar](20) NULL,
	[code_set_nm] [varchar](256) NULL,
	[condition_cd] [varchar](10) NULL,
	[label_txt] [varchar](300) NULL,
	[state_cd] [varchar](10) NULL,
	[custom_subform_metadata_uid] [bigint] NULL,
	[page_set] [varchar](50) NULL,
	[data_type] [varchar](50) NULL,
	[Field_size] [varchar](10) NULL,
	[LDF_PAGE_SET] [varchar](50) NULL
) ON [PRIMARY]
END