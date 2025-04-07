IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Lab_test'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Lab_test
        (
            lab_test_cd              varchar(20)  NOT NULL,
            laboratory_id            varchar(20)  NOT NULL,
            lab_test_desc_txt        varchar(100) NULL,
            test_type_cd             varchar(20)  NOT NULL,
            nbs_uid                  bigint       NOT NULL,
            effective_from_time      datetime     NULL,
            effective_to_time        datetime     NULL,
            default_prog_area_cd     varchar(20)  NULL,
            default_condition_cd     varchar(20)  NULL,
            drug_test_ind            char(1)      NULL,
            organism_result_test_ind char(1)      NULL,
            indent_level_nbr         smallint     NULL,
            pa_derivation_exclude_cd char(1)      NULL,
            CONSTRAINT PK_Lab_test183 PRIMARY KEY CLUSTERED (lab_test_cd, laboratory_id)
        ) ON [PRIMARY]

        ALTER TABLE dbo.nrt_srte_Lab_test
            ADD DEFAULT ('N') FOR pa_derivation_exclude_cd
    END;