IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Labtest_Progarea_Mapping'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Labtest_Progarea_Mapping
        (
            lab_test_cd              varchar(20)  NOT NULL,
            laboratory_id            varchar(20)  NOT NULL,
            lab_test_desc_txt        varchar(100) NULL,
            test_type_cd             varchar(20)  NOT NULL,
            condition_cd             varchar(20)  NULL,
            condition_short_nm       varchar(50)  NULL,
            condition_desc_txt       varchar(300) NULL,
            prog_area_cd             varchar(20)  NOT NULL,
            prog_area_desc_txt       varchar(50)  NOT NULL,
            organism_result_test_ind char(1)      NULL,
            indent_level_nbr         smallint     NULL,
            CONSTRAINT PK_Labtest_Progarea_Mapping PRIMARY KEY CLUSTERED (lab_test_cd, laboratory_id)
        ) ON [PRIMARY]
    END;