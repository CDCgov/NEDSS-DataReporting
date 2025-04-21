IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'ldf_generic1'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE [dbo].[LDF_GENERIC1](
            [INVESTIGATION_KEY] [numeric](20, 0) NULL,
            [INVESTIGATION_LOCAL_ID] [varchar](50) NULL,
            [PROGRAM_JURISDICTION_OID] [numeric](20, 0) NULL,
            [PATIENT_KEY] [numeric](20, 0) NULL,
            [PATIENT_LOCAL_ID] [varchar](50) NULL,
            [DISEASE_NAME] [varchar](50) NULL,
            [DISEASE_CD] [varchar](10) NULL
        ) ON [PRIMARY]
END;