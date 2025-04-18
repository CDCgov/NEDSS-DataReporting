IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LDF_DATAMART_TABLE_REF' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[LDF_DATAMART_TABLE_REF](
        [LDF_DATAMART_TABLE_REF_UID] [bigint] IDENTITY(1,1) NOT NULL,
        [CONDITION_CD] [varchar](30) NULL,
        [CONDITION_DESC] [varchar](100) NULL,
        [LDF_GROUP_ID] [int] NOT NULL,
        [DATAMART_NAME] [varchar](30) NOT NULL,
        [LINKED_FACT_TABLE] [varchar](50) NOT NULL,
        [ENTITY_DESC] [varchar](50) NULL
    ) ON [PRIMARY]
END