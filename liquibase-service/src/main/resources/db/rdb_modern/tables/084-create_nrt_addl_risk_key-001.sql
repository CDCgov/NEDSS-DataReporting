IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_addl_risk_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_addl_risk_key (
                                               D_ADDL_RISK_KEY bigint IDENTITY (2,1) NOT NULL,
                                               TB_PAM_UID bigint NOT NULL,
                                               NBS_Case_Answer_UID bigint NOT NULL
                                              
        );

        declare @max bigint;
        select @max=max(D_ADDL_RISK_KEY)+1 from dbo.d_addl_risk ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_addl_risk_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_organization_key'))
            BEGIN
                ALTER TABLE dbo.nrt_organization_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_organization_key'))
            BEGIN
                ALTER TABLE dbo.nrt_organization_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;
