IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Snomed_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Snomed_code
        (
            snomed_cd                varchar(20)  NOT NULL,
            snomed_desc_txt          varchar(100) NULL,
            source_concept_id        varchar(20)  NOT NULL,
            source_version_id        varchar(20)  NOT NULL,
            status_cd                char(1)      NULL,
            status_time              datetime     NULL,
            nbs_uid                  int          NULL,
            effective_from_time      datetime     NULL,
            effective_to_time        datetime     NULL,
            pa_derivation_exclude_cd char(1)      NULL,
            CONSTRAINT PK_SNOMED_code180 PRIMARY KEY CLUSTERED (snomed_cd)
        ) ON [PRIMARY]

        CREATE UNIQUE NONCLUSTERED INDEX UQ__Snomed_code__284DF453 ON dbo.nrt_srte_Snomed_code (nbs_uid)

        ALTER TABLE dbo.nrt_srte_Snomed_code
            ADD DEFAULT ('N') FOR pa_derivation_exclude_cd
    END;