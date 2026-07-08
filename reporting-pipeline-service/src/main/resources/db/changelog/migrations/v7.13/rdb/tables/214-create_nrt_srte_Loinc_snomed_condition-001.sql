IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Loinc_snomed_condition'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Loinc_snomed_condition
        (
            loinc_snomed_cc_uid bigint      NOT NULL,
            snomed_cd           varchar(20) NULL,
            loinc_cd            varchar(20) NOT NULL,
            condition_cd        varchar(20) NULL,
            status_cd           char(1)     NULL,
            status_time         datetime    NULL,
            effective_from_time datetime    NULL,
            effective_to_time   datetime    NULL,
            CONSTRAINT PK_Dwyer_event187 PRIMARY KEY CLUSTERED (loinc_snomed_cc_uid)
        ) ON [PRIMARY]
    END;