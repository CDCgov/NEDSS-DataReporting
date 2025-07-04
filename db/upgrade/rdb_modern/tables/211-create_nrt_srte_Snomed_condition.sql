IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Snomed_condition'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Snomed_condition
        (
            snomed_cd           varchar(20)  NOT NULL,
            condition_cd        varchar(20)  NOT NULL,
            disease_nm          varchar(200) NULL,
            organism_set_nm     varchar(100) NULL,
            status_cd           char(1)      NULL,
            status_time         datetime     NULL,
            effective_from_time datetime     NULL,
            effective_to_time   datetime     NULL,
            PRIMARY KEY (snomed_cd)
        ) ON [PRIMARY]
    END;