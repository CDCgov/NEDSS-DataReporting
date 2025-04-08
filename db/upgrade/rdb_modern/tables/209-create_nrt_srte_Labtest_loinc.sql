IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Labtest_loinc'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Labtest_loinc
        (
            lab_test_cd         varchar(20) NOT NULL,
            laboratory_id       varchar(20) NOT NULL,
            loinc_cd            varchar(20) NOT NULL,
            effective_from_time datetime    NULL,
            effective_to_time   datetime    NULL,
            status_cd           char(1)     NULL,
            status_time         datetime    NULL,
            CONSTRAINT PK_T_98189 PRIMARY KEY CLUSTERED (lab_test_cd, laboratory_id, loinc_cd)
        ) ON [PRIMARY]
    END;