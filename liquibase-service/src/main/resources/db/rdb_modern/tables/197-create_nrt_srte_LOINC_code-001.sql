IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_LOINC_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_LOINC_code
        (
            loinc_cd                 varchar(20)  NOT NULL,
            component_name           varchar(200) NULL,
            property                 varchar(10)  NULL,
            time_aspect              varchar(10)  NULL,
            system_cd                varchar(50)  NULL,
            scale_type               varchar(20)  NULL,
            method_type              varchar(50)  NULL,
            display_nm               varchar(300) NULL,
            nbs_uid                  bigint       NULL,
            effective_from_time      datetime     NULL,
            effective_to_time        datetime     NULL,
            related_class_cd         varchar(50)  NULL,
            pa_derivation_exclude_cd char(1)      NULL,
            CONSTRAINT PK_LOINC_code179 PRIMARY KEY CLUSTERED (loinc_cd)
        ) ON [PRIMARY]

        CREATE NONCLUSTERED INDEX IDX_LOINC_code_02172021_06 ON dbo.nrt_srte_LOINC_code (time_aspect, system_cd)
        CREATE UNIQUE NONCLUSTERED INDEX UQ__LOINC_code__47DBAE45 ON dbo.nrt_srte_LOINC_code (nbs_uid)

        ALTER TABLE dbo.nrt_srte_LOINC_code
            ADD DEFAULT ('N') FOR pa_derivation_exclude_cd
    END;