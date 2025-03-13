IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_disease_site_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_disease_site_key (
                                               D_DISEASE_SITE_KEY bigint IDENTITY (2,1) NOT NULL,
                                               NBS_Case_Answer_UID bigint NOT NULL,
                                               TB_PAM_UID bigint NOT NULL
                                              
        );

        declare @max bigint;
        select @max=max(D_DISEASE_SITE_KEY)+1 from dbo.d_disease_site ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_disease_site_key', RESEED, @max);
    END
