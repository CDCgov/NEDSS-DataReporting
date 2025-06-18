IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Snomed_condition' and xtype = 'U')
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
            effective_to_time   datetime     NULL
        ) ON [PRIMARY]
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_srte_Snomed_condition'))
    BEGIN
        ALTER TABLE dbo.nrt_srte_Snomed_condition
        ADD CONSTRAINT pk_nrt_srte_Snomed_condition PRIMARY KEY (snomed_cd);
    END;