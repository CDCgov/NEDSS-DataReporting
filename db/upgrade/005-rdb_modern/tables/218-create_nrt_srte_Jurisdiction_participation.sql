IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Jurisdiction_participation'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Jurisdiction_participation
        (
            jurisdiction_cd     varchar(20) NOT NULL,
            fips_cd             varchar(20) NOT NULL,
            type_cd             varchar(20) NOT NULL,
            effective_from_time datetime    NULL,
            effective_to_time   datetime    NULL,
            CONSTRAINT PK_City_Jurisdiction176 PRIMARY KEY CLUSTERED (jurisdiction_cd, fips_cd, type_cd)
        ) ON [PRIMARY]

        CREATE NONCLUSTERED INDEX IDX_JUR_PART_ELR1 ON dbo.nrt_srte_Jurisdiction_participation (type_cd)
        CREATE NONCLUSTERED INDEX IDX_JUR_PART_ELR2 ON dbo.nrt_srte_Jurisdiction_participation (fips_cd, type_cd)
    END;