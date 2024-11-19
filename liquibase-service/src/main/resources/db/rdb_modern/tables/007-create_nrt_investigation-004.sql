IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation' and xtype = 'U')
BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'investigation_form_cd' AND Object_ID = Object_ID(N'nrt_investigation'))
            BEGIN
                ALTER TABLE dbo.nrt_investigation ADD investigation_form_cd VARCHAR(50);
            END;

END;
