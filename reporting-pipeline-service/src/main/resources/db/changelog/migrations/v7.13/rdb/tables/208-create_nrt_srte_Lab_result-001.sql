IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Lab_result'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Lab_result
        (
            lab_result_cd            varchar(20)  NOT NULL,
            laboratory_id            varchar(20)  NOT NULL,
            lab_result_desc_txt      varchar(50)  NULL,
            effective_from_time      datetime     NULL,
            effective_to_time        datetime     NULL,
            nbs_uid                  bigint       NULL,
            default_prog_area_cd     varchar(20)  NULL,
            organism_name_ind        char(1)      NULL,
            default_condition_cd     varchar(20)  NULL,
            pa_derivation_exclude_cd char(1)      NULL,
            code_system_cd           varchar(300) NULL,
            code_set_nm              varchar(256) NULL,
            CONSTRAINT PK_Lab_result204 PRIMARY KEY CLUSTERED (lab_result_cd, laboratory_id)
        ) ON [PRIMARY]

        CREATE UNIQUE NONCLUSTERED INDEX UQ__Lab_result__1BE81D6E ON dbo.nrt_srte_Lab_result (nbs_uid)

        ALTER TABLE dbo.nrt_srte_Lab_result
            ADD DEFAULT ('N') FOR pa_derivation_exclude_cd
    END;