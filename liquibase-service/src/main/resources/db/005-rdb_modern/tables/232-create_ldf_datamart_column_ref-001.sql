IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LDF_DATAMART_COLUMN_REF' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[LDF_DATAMART_COLUMN_REF](
        [LDF_DATAMART_COLUMN_REF_UID] [bigint] NOT NULL,
        [CONDITION_CD] [varchar](50) NOT NULL,
        [LDF_LABEL] [varchar](50) NOT NULL,
        [DATAMART_COLUMN_NM] [varchar](50) NOT NULL,
        [LDF_UID] [bigint] NOT NULL,
        [CDC_NATIONAL_ID] [varchar](50) NOT NULL,
        [BUSINESS_OBJECT_NM] [varchar](50) NULL,
        [LDF_PAGE_SET] [varchar](50) NULL
    ) ON [PRIMARY]
END
