IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'TB_PAM_LDF' and xtype = 'U')
BEGIN
    CREATE TABLE [dbo].[TB_PAM_LDF](
        [INVESTIGATION_KEY] [numeric](20, 0) NULL,
        [TB_PAM_UID] [numeric](20, 0) NULL,
        [add_time] [datetime2](3) NULL
    ) ON [PRIMARY]
END;