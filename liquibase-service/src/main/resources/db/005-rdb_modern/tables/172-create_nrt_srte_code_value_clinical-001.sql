IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Code_value_clinical' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[nrt_srte_Code_value_clinical](
        [code_set_nm] [varchar](256) NOT NULL,
        [seq_num] [smallint] NOT NULL,
        [code] [varchar](20) NOT NULL,
        [snomed_cd] [varchar](20) NULL,
        [assigning_authority_cd] [varchar](199) NULL,
        [assigning_authority_desc_txt] [varchar](100) NULL,
        [order_number] [smallint] NOT NULL,
        [code_desc_txt] [varchar](300) NULL,
        [code_short_desc_txt] [varchar](50) NULL,
        [code_system_code] [varchar](300) NULL,
        [code_system_desc_txt] [varchar](100) NULL,
        [common_name] [varchar](300) NULL,
        [other_names] [varchar](300) NULL,
        [status_cd] [char](1) NULL,
        [status_time] [datetime] NULL,
    CONSTRAINT [PK_Clinical_code_value257] PRIMARY KEY CLUSTERED 
    (
        [code_set_nm] ASC,
        [seq_num] ASC,
        [code] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
END;